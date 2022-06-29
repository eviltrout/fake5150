#include <gdnative_api_struct.gen.h>
#include <string.h>

#include <stdio.h>
#include <time.h>
#include "sarien.h"
#include "agi.h"
#include "text.h"
#include "graphics.h"
#include "sprite.h"

typedef struct user_data_struct {
	godot_pool_byte_array vram;
} user_data_struct;

static int loaded_sarien = 0;

struct sarien_options opt;
struct agi_game game;
static unsigned char* vram_ptr;

static int  init_vidmode  (void);
static int  deinit_vidmode  (void);
static void godot_put_block (int, int, int, int);
static void godot_putpixels  (int, int, int, unsigned char *);
static void godot_timer (void);
int   godot_is_keypress (void);
int   godot_get_keypress(void);

static struct gfx_driver gfx_godot = {
  init_vidmode,
  deinit_vidmode,
  godot_put_block,
  godot_putpixels,
  godot_timer,
  godot_is_keypress,
  godot_get_keypress
};
extern struct gfx_driver *gfx;


// GDNative supports a large collection of functions for calling back
// into the main Godot executable. In order for your module to have
// access to these functions, GDNative provides your application with
// a struct containing pointers to all these functions.
const godot_gdnative_core_api_struct *api = NULL;
const godot_gdnative_ext_nativescript_api_struct *nativescript_api = NULL;

// These are forward declarations for the functions we'll be implementing
// for our object. A constructor and destructor are both necessary.
GDCALLINGCONV void *sarien_constructor(godot_object *p_instance, void *p_method_data);
GDCALLINGCONV void sarien_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data);
godot_variant sarien_get_frame(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);
void init_sarien(user_data_struct *user_data);
void sarien_tick(void);

void log_it(char* msg) {
	godot_string str;
  api->godot_string_new(&str);
  api->godot_string_parse_utf8(&str, msg);
  api->godot_print(&str);
  api->godot_string_destroy(&str);
}

void report(char *fmt, ...) {
  char buf[5000];
  va_list va;
  va_start (va, fmt);
  vsprintf (buf, fmt, va);
  va_end (va);
  log_it(buf);
}

void et_log(char *fmt, ...) {
  char buf[5000];
  va_list va;
  va_start (va, fmt);
  vsprintf (buf, fmt, va);
  va_end (va);
  log_it(buf);
}

void init_sarien(user_data_struct *user_data) {
  if (loaded_sarien) {
    return;
  }
	godot_pool_byte_array_write_access *write = api->godot_pool_byte_array_write(&user_data->vram);
	vram_ptr = api->godot_pool_byte_array_write_access_ptr(write);

  loaded_sarien = 1;

  memset (&opt, 0, sizeof (struct sarien_options));
  opt.scale = 1;
  opt.fixratio = TRUE;
  opt.gfxhacks = TRUE;
  opt.hires = FALSE;
  opt.nosound = true;
  clock_count = 0;
  clock_ticks = 0;

  if (agi_detect_game("sq1") == err_OK) {
    et_log("loaded sarien %x, %x", game.crc, game.ver);

    game.sbuf = calloc (_WIDTH, _HEIGHT);
    game.hires = calloc (_WIDTH*2, _HEIGHT);
    game.color_fg = 15;
    game.color_bg = 0;

    gfx = &gfx_godot;

    if (init_sprites() != err_OK) {
      et_log("error: init_sprites()");
    }

    if (init_video() != err_OK) {
      et_log("error: init_video()");
    }

    game.state = STATE_LOADED;
    init_sound();

    for (int i = 0; i < MAX_DIRS; i++) {
      memset (&game.ev_keyp[i],  0, sizeof (struct agi_event));
    }
    if (agi_init() != err_OK) {
      et_log("error initializing");
    }

    setvar (V_computer, 0);   /* IBM PC (4 = Atari ST) */
    setvar (V_soundgen, 0);   /* IBM PC SOUND */
    setvar (V_monitor, 0x3);  /* EGA monitor */
    setvar (V_max_input_chars, 38);

    game.input_mode = INPUT_NONE;
    game.input_enabled = 0;
    game.has_prompt = 0;

    game.state = STATE_RUNNING;

    stop_sound ();
    clear_screen (0);

    game.horizon = HORIZON;
    game.player_control = FALSE;

    setflag (F_logic_zero_firsttime, TRUE); /* not in 2.917 */
    setflag (F_new_room_exec, TRUE);  /* needed for MUMG and SQ2! */
    setflag (F_sound_on, FALSE);   /* enable sound */
    setvar (V_time_delay, 2);   /* "normal" speed */

    game.gfx_mode = TRUE;
    game.quit_prog_now = FALSE;
    game.clock_enabled = TRUE;
    game.line_user_input = 22;

    setflag (F_entered_cli, FALSE);
    setflag (F_said_accepted_input, FALSE);
    game.vars[V_word_not_found] = 0;
    game.vars[V_key] = 0;
  }
	api->godot_pool_byte_array_write_access_destroy(write);
  vram_ptr = NULL;
}

static int init_vidmode  (void) {
  et_log("init_vidmode");
  return err_OK;
}

static int deinit_vidmode  (void) {
  et_log("deinit_vidmode");
  return err_OK;
}

static void godot_put_block (int x1, int y1, int x2, int y2) {
  if (vram_ptr == NULL) {
    return;
  }
}

static void godot_putpixels  (int x, int y, int w, unsigned char *pixels) {
  unsigned char *v = vram_ptr + ((y * 320) + x) * 3;
  for (int i=0; i<w; i++) {
    unsigned char *c = palette + (*(pixels++) * 3);
    *(v++) = *(c++);
    *(v++) = *(c++);
    *(v++) = *(c++);
  }
}

static void godot_timer (void) {
}

int godot_is_keypress (void) {
  return 0;
}
int godot_get_keypress(void) {
  return 0;
}

static void interpret_cycle ()
{
  int old_sound, old_score;

  if (game.player_control)
    game.vars[V_ego_dir] = game.view_table[0].direction;
  else
    game.view_table[0].direction = game.vars[V_ego_dir];

  check_all_motions ();

  old_score = game.vars[V_score];
  old_sound = getflag (F_sound_on);

  game.exit_all_logics = FALSE;
  while (run_logic (0) == 0 && !game.quit_prog_now) {
    game.vars[V_word_not_found] = 0;
    game.vars[V_border_touch_obj] = 0;
    game.vars[V_border_code] = 0;
    old_score = game.vars[V_score];
    setflag (F_entered_cli, FALSE);
    game.exit_all_logics = FALSE;
    /* reset_controllers (); */
  }
  /* reset_controllers (); */

  game.view_table[0].direction = game.vars[V_ego_dir];

  if (game.vars[V_score] != old_score || getflag(F_sound_on) != old_sound)
    write_status ();

  game.vars[V_border_touch_obj] = 0;
  game.vars[V_border_code] = 0;
  setflag (F_new_room_exec, FALSE);
  setflag (F_restart_game, FALSE);
  setflag (F_restore_just_ran, FALSE);

  if (game.gfx_mode) {
    update_viewtable ();
    do_update ();
  }
}

void sarien_tick(void) {
  if (!main_cycle()) { 
    return;
  }

  if (getvar (V_time_delay) == 0 ||
      (1 + clock_count) % getvar (V_time_delay) == 0)
  {
    if (!game.has_prompt && game.input_mode == INPUT_NORMAL) {
      write_prompt ();
      game.has_prompt = 1;
    } else
      if (game.has_prompt && game.input_mode == INPUT_NONE) {
        write_prompt ();
        game.has_prompt = 0;
      }

    interpret_cycle (); 

    setflag (F_entered_cli, FALSE);
    setflag (F_said_accepted_input, FALSE);
    game.vars[V_word_not_found] = 0;
    game.vars[V_key] = 0;
  }
}

// `gdnative_init` is a function that initializes our dynamic library.
// Godot will give it a pointer to a structure that contains various bits of
// information we may find useful among which the pointers to our API structures.
void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *p_options) {
	api = p_options->api_struct;

	// Find NativeScript extensions.
	for (int i = 0; i < api->num_extensions; i++) {
		switch (api->extensions[i]->type) {
			case GDNATIVE_EXT_NATIVESCRIPT: {
				nativescript_api = (godot_gdnative_ext_nativescript_api_struct *)api->extensions[i];
			}; break;
			default:
				break;
		};
	};
}

// `gdnative_terminate` which is called before the library is unloaded.
// Godot will unload the library when no object uses it anymore.
void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *p_options) {
	api = NULL;
	nativescript_api = NULL;
}

void GDN_EXPORT godot_nativescript_init(void *p_handle) {
	godot_instance_create_func create = { NULL, NULL, NULL };
	create.create_func = &sarien_constructor;
	godot_instance_destroy_func destroy = { NULL, NULL, NULL };
	destroy.destroy_func = &sarien_destructor;
	nativescript_api->godot_nativescript_register_class(p_handle, "SARIEN", "Reference", create, destroy);
	godot_instance_method get_frame = { NULL, NULL, NULL };
	get_frame.method = &sarien_get_frame;
	godot_method_attributes attributes = { GODOT_METHOD_RPC_MODE_DISABLED };
	nativescript_api->godot_nativescript_register_method(p_handle, "SARIEN", "get_frame", attributes, get_frame);
}

GDCALLINGCONV void *sarien_constructor(godot_object *p_instance, void *p_method_data) {
	user_data_struct *user_data = api->godot_alloc(sizeof(user_data_struct));
	api->godot_pool_byte_array_new(&user_data->vram);
	api->godot_pool_byte_array_resize(&user_data->vram, 320*200*3);
  init_sarien(user_data);

	return user_data;
}

GDCALLINGCONV void sarien_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data) {
	user_data_struct *user_data = (user_data_struct*) p_user_data;
	api->godot_pool_byte_array_destroy(&user_data->vram);
	api->godot_free(p_user_data);
}

godot_variant sarien_get_frame(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
	godot_variant ret;
	user_data_struct *user_data = (user_data_struct *)p_user_data;

	godot_pool_byte_array_write_access *write = api->godot_pool_byte_array_write(&user_data->vram);
	vram_ptr = api->godot_pool_byte_array_write_access_ptr(write);
  sarien_tick();
	api->godot_pool_byte_array_write_access_destroy(write);
  vram_ptr = NULL;

	api->godot_variant_new_pool_byte_array(&ret, &user_data->vram);

	return ret;
}
