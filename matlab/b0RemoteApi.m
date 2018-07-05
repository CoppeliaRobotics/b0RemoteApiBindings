classdef b0RemoteApi < handle

    properties
        libName;
        hFile;
        pongReceived;
        channelName;
        serviceCallTopic;
        defaultPublisherTopic;
        defaultSubscriberTopic;
        nextDefaultSubscriberHandle;
        nextDedicatedPublisherHandle;
        nextDedicatedSubscriberHandle;
        node;
        clientId;
        serviceClient;
        defaultPublisher;
        defaultSubscriber;
        allSubscribers;
        allDedicatedPublishers;
        nodeName;
        inactivityToleranceInSec;
        setupSubscribersAsynchronously;
    end
    
    properties (Constant)
        % Scene object types
        sim_object_shape_type           =0;
        sim_object_joint_type           =1;
        sim_object_graph_type           =2;
        sim_object_camera_type          =3;
        sim_object_dummy_type           =4;
        sim_object_proximitysensor_type =5;
        sim_object_reserved1            =6;
        sim_object_reserved2            =7;
        sim_object_path_type            =8;
        sim_object_visionsensor_type    =9;
        sim_object_volume_type          =10;
        sim_object_mill_type            =11;
        sim_object_forcesensor_type     =12;
        sim_object_light_type           =13;
        sim_object_mirror_type          =14;

        %General object types
        sim_appobj_object_type          =109;
        sim_appobj_collision_type       =110;
        sim_appobj_distance_type        =111;
        sim_appobj_simulation_type      =112;
        sim_appobj_ik_type              =113;
        sim_appobj_constraintsolver_type=114;
        sim_appobj_collection_type      =115;
        sim_appobj_ui_type              =116;
        sim_appobj_script_type          =117;
        sim_appobj_pathplanning_type    =118;
        sim_appobj_RESERVED_type        =119;
        sim_appobj_texture_type         =120;

        % Ik calculation methods
        sim_ik_pseudo_inverse_method        =0;
        sim_ik_damped_least_squares_method  =1;
        sim_ik_jacobian_transpose_method    =2;

        % Ik constraints
        sim_ik_x_constraint         =1;
        sim_ik_y_constraint         =2;
        sim_ik_z_constraint         =4;
        sim_ik_alpha_beta_constraint=8;
        sim_ik_gamma_constraint     =16;
        sim_ik_avoidance_constraint =64;

        % Ik calculation results
        sim_ikresult_not_performed  =0;
        sim_ikresult_success        =1;
        sim_ikresult_fail           =2;

        % Scene object sub-types
        sim_light_omnidirectional_subtype   =1;
        sim_light_spot_subtype              =2;
        sim_light_directional_subtype       =3;
        sim_joint_revolute_subtype          =10;
        sim_joint_prismatic_subtype         =11;
        sim_joint_spherical_subtype         =12;
        sim_shape_simpleshape_subtype       =20;
        sim_shape_multishape_subtype        =21;
        sim_proximitysensor_pyramid_subtype =30;
        sim_proximitysensor_cylinder_subtype=31;
        sim_proximitysensor_disc_subtype    =32;
        sim_proximitysensor_cone_subtype    =33;
        sim_proximitysensor_ray_subtype     =34;
        sim_mill_pyramid_subtype            =40;
        sim_mill_cylinder_subtype           =41;
        sim_mill_disc_subtype               =42;
        sim_mill_cone_subtype               =42;
        sim_object_no_subtype               =200;


        %Scene object main properties
        sim_objectspecialproperty_collidable                    =1;
        sim_objectspecialproperty_measurable                    =2;
        sim_objectspecialproperty_detectable_ultrasonic         =16;
        sim_objectspecialproperty_detectable_infrared           =32;
        sim_objectspecialproperty_detectable_laser              =64;
        sim_objectspecialproperty_detectable_inductive          =128;
        sim_objectspecialproperty_detectable_capacitive         =256;
        sim_objectspecialproperty_renderable                    =512;
        sim_objectspecialproperty_detectable_all                =496;
        sim_objectspecialproperty_cuttable                      =1024;
        sim_objectspecialproperty_pathplanning_ignored          =2048;

        % Model properties
        sim_modelproperty_not_collidable                =1;
        sim_modelproperty_not_measurable                =2;
        sim_modelproperty_not_renderable                =4;
        sim_modelproperty_not_detectable                =8;
        sim_modelproperty_not_cuttable                  =16;
        sim_modelproperty_not_dynamic                   =32;
        sim_modelproperty_not_respondable               =64;
        sim_modelproperty_not_reset                     =128;
        sim_modelproperty_not_visible                   =256;
        sim_modelproperty_not_model                     =61440;


        % Check the documentation instead of comments below!!
        sim_message_ui_button_state_change  =0;
        sim_message_reserved9               =1;
        sim_message_object_selection_changed=2;
        sim_message_reserved10              =3;
        sim_message_model_loaded            =4;
        sim_message_reserved11              =5;
        sim_message_keypress                =6;
        sim_message_bannerclicked           =7;
        sim_message_for_c_api_only_start        =256;
        sim_message_reserved1                   =257;
        sim_message_reserved2                   =258;
        sim_message_reserved3                   =259;
        sim_message_eventcallback_scenesave     =260;
        sim_message_eventcallback_modelsave     =261;
        sim_message_eventcallback_moduleopen    =262;
        sim_message_eventcallback_modulehandle  =263;
        sim_message_eventcallback_moduleclose   =264;
        sim_message_reserved4                   =265;
        sim_message_reserved5                   =266;
        sim_message_reserved6                   =267;
        sim_message_reserved7                   =268;
        sim_message_eventcallback_instancepass  =269;
        sim_message_eventcallback_broadcast     =270;
        sim_message_eventcallback_imagefilter_enumreset =271;
        sim_message_eventcallback_imagefilter_enumerate      =272;
        sim_message_eventcallback_imagefilter_adjustparams   =273;
        sim_message_eventcallback_imagefilter_reserved       =274;
        sim_message_eventcallback_imagefilter_process        =275;
        sim_message_eventcallback_reserved1                  =276;
        sim_message_eventcallback_reserved2                  =277;
        sim_message_eventcallback_reserved3                  =278;
        sim_message_eventcallback_reserved4                  =279;
        sim_message_eventcallback_abouttoundo                =280;
        sim_message_eventcallback_undoperformed              =281;
        sim_message_eventcallback_abouttoredo                =282;
        sim_message_eventcallback_redoperformed              =283;
        sim_message_eventcallback_scripticondblclick         =284;
        sim_message_eventcallback_simulationabouttostart     =285;
        sim_message_eventcallback_simulationended            =286;
        sim_message_eventcallback_reserved5                  =287;
        sim_message_eventcallback_keypress                   =288;
        sim_message_eventcallback_modulehandleinsensingpart  =289;
        sim_message_eventcallback_renderingpass              =290;
        sim_message_eventcallback_bannerclicked              =291;
        sim_message_eventcallback_menuitemselected           =292;
        sim_message_eventcallback_refreshdialogs             =293;
        sim_message_eventcallback_sceneloaded                =294;
        sim_message_eventcallback_modelloaded                =295;
        sim_message_eventcallback_instanceswitch             =296;
        sim_message_eventcallback_guipass                    =297;
        sim_message_eventcallback_mainscriptabouttobecalled  =298;
        sim_message_eventcallback_rmlposition                =299;
        sim_message_eventcallback_rmlvelocity                =300;

        sim_message_simulation_start_resume_request          =4096;
        sim_message_simulation_pause_request                 =4097;
        sim_message_simulation_stop_request                  =4098;

        % Scene object properties
        sim_objectproperty_collapsed                =16;
        sim_objectproperty_selectable               =32;
        sim_objectproperty_reserved7                =64;
        sim_objectproperty_selectmodelbaseinstead   =128;
        sim_objectproperty_dontshowasinsidemodel    =256;
        sim_objectproperty_canupdatedna             =1024;
        sim_objectproperty_selectinvisible          =2048;
        sim_objectproperty_depthinvisible           =4096;



        % type of arguments (input and output) for custom lua commands
        sim_lua_arg_nil     =0;
        sim_lua_arg_bool    =1;
        sim_lua_arg_int     =2;
        sim_lua_arg_float   =3;
        sim_lua_arg_string  =4;
        sim_lua_arg_invalid =5;
        sim_lua_arg_table   =8;

        % custom user interface properties
        sim_ui_property_visible                     =1;
        sim_ui_property_visibleduringsimulationonly =2;
        sim_ui_property_moveable                    =4;
        sim_ui_property_relativetoleftborder        =8;
        sim_ui_property_relativetotopborder         =16;
        sim_ui_property_fixedwidthfont              =32;
        sim_ui_property_systemblock                 =64;
        sim_ui_property_settocenter                 =128;
        sim_ui_property_rolledup                    =256;
        sim_ui_property_selectassociatedobject      =512;
        sim_ui_property_visiblewhenobjectselected   =1024;


        % button properties
        sim_buttonproperty_button               =0;
        sim_buttonproperty_label                =1;
        sim_buttonproperty_slider               =2;
        sim_buttonproperty_editbox              =3;
        sim_buttonproperty_staydown             =8;
        sim_buttonproperty_enabled              =16;
        sim_buttonproperty_borderless           =32;
        sim_buttonproperty_horizontallycentered =64;
        sim_buttonproperty_ignoremouse          =128;
        sim_buttonproperty_isdown               =256;
        sim_buttonproperty_transparent          =512;
        sim_buttonproperty_nobackgroundcolor    =1024;
        sim_buttonproperty_rollupaction         =2048;
        sim_buttonproperty_closeaction          =4096;
        sim_buttonproperty_verticallycentered   =8192;
        sim_buttonproperty_downupevent          =16384;


        % Simulation status
        sim_simulation_stopped                      =0;
        sim_simulation_paused                       =8;
        sim_simulation_advancing                    =16;
        sim_simulation_advancing_firstafterstop     =16;
        sim_simulation_advancing_running            =17;
        sim_simulation_advancing_lastbeforepause    =19;
        sim_simulation_advancing_firstafterpause    =20;
        sim_simulation_advancing_abouttostop        =21;
        sim_simulation_advancing_lastbeforestop     =22;


        % Script execution result (first return value)
        sim_script_no_error                 =0;
        sim_script_main_script_nonexistent  =1;
        sim_script_main_script_not_called   =2;
        sim_script_reentrance_error         =4;
        sim_script_lua_error                =8;
        sim_script_call_error               =16;


        % Script types
        sim_scripttype_mainscript   =0;
        sim_scripttype_childscript  =1;
        sim_scripttype_jointctrlcallback  =4;
        sim_scripttype_contactcallback  =5;
        sim_scripttype_customizationscript  =6;
        sim_scripttype_generalcallback  =7;

        % API call error messages
        sim_api_errormessage_ignore =0;
        sim_api_errormessage_report =1;
        sim_api_errormessage_output =2;


        % special argument of some functions
        sim_handle_all                      =-2;
        sim_handle_all_except_explicit      =-3;
        sim_handle_self                     =-4;
        sim_handle_main_script              =-5;
        sim_handle_tree                     =-6;
        sim_handle_chain                    =-7;
        sim_handle_single                   =-8;
        sim_handle_default                  =-9;
        sim_handle_all_except_self          =-10;
        sim_handle_parent                   =-11;

        % special handle flags
        sim_handleflag_assembly             =4194304;
        sim_handleflag_model                =8388608;


        % distance calculation methods
        sim_distcalcmethod_dl               =0;
        sim_distcalcmethod_dac              =1;
        sim_distcalcmethod_max_dl_dac       =2;
        sim_distcalcmethod_dl_and_dac       =3;
        sim_distcalcmethod_sqrt_dl2_and_dac2=4;
        sim_distcalcmethod_dl_if_nonzero    =5;
        sim_distcalcmethod_dac_if_nonzero   =6;


        % Generic dialog styles
        sim_dlgstyle_message        =0;
        sim_dlgstyle_input          =1;
        sim_dlgstyle_ok             =2;
        sim_dlgstyle_ok_cancel      =3;
        sim_dlgstyle_yes_no         =4;
        sim_dlgstyle_dont_center    =32;

        % Generic dialog return values
        sim_dlgret_still_open   =0;
        sim_dlgret_ok           =1;
        sim_dlgret_cancel       =2;
        sim_dlgret_yes          =3;
        sim_dlgret_no           =4;


        % Path properties
        sim_pathproperty_show_line                          =1;
        sim_pathproperty_show_orientation                   =2;
        sim_pathproperty_closed_path                        =4;
        sim_pathproperty_automatic_orientation              =8;
        sim_pathproperty_invert_velocity                    =16;
        sim_pathproperty_infinite_acceleration              =32;
        sim_pathproperty_flat_path                          =64;
        sim_pathproperty_show_position                      =128;
        sim_pathproperty_auto_velocity_profile_translation  =256;
        sim_pathproperty_auto_velocity_profile_rotation     =512;
        sim_pathproperty_endpoints_at_zero                  =1024;
        sim_pathproperty_keep_x_up                          =2048;


        % drawing objects
        sim_drawing_points          =0;
        sim_drawing_lines           =1;
        sim_drawing_triangles       =2;
        sim_drawing_trianglepoints  =3;
        sim_drawing_quadpoints      =4;
        sim_drawing_discpoints      =5;
        sim_drawing_cubepoints      =6;
        sim_drawing_spherepoints    =7;

        sim_drawing_itemcolors              =32;
        sim_drawing_vertexcolors            =64;
        sim_drawing_itemsizes               =128;
        sim_drawing_backfaceculling         =256;
        sim_drawing_wireframe               =512;
        sim_drawing_painttag                =1024;
        sim_drawing_followparentvisibility  =2048;
        sim_drawing_cyclic                  =4096;
        sim_drawing_50percenttransparency   =8192;
        sim_drawing_25percenttransparency   =16384;
        sim_drawing_12percenttransparency   =32768;
        sim_drawing_emissioncolor           =65536;
        sim_drawing_facingcamera            =131072;
        sim_drawing_overlay                 =262144;
        sim_drawing_itemtransparency        =524288;

        % banner values
        sim_banner_left                     =1;
        sim_banner_right                    =2;
        sim_banner_nobackground             =4;
        sim_banner_overlay                  =8;
        sim_banner_followparentvisibility   =16;
        sim_banner_clickselectsparent       =32;
        sim_banner_clicktriggersevent       =64;
        sim_banner_facingcamera             =128;
        sim_banner_fullyfacingcamera        =256;
        sim_banner_backfaceculling          =512;
        sim_banner_keepsamesize             =1024;
        sim_banner_bitmapfont               =2048;

        % particle objects
        sim_particle_points1        =0;
        sim_particle_points2        =1;
        sim_particle_points4        =2;
        sim_particle_roughspheres   =3;
        sim_particle_spheres        =4;

        sim_particle_respondable1to4        =32;
        sim_particle_respondable5to8        =64;
        sim_particle_particlerespondable    =128;
        sim_particle_ignoresgravity         =256;
        sim_particle_invisible              =512;
        sim_particle_itemsizes              =1024;
        sim_particle_itemdensities          =2048;
        sim_particle_itemcolors             =4096;
        sim_particle_cyclic                 =8192;
        sim_particle_emissioncolor          =16384;
        sim_particle_water                  =32768;
        sim_particle_painttag               =65536;

        % custom user interface menu attributes
        sim_ui_menu_title       =1;
        sim_ui_menu_minimize    =2;
        sim_ui_menu_close       =4;
        sim_ui_menu_systemblock =8;



        % Boolean parameters
        sim_boolparam_hierarchy_visible                 =0;
        sim_boolparam_console_visible                   =1;
        sim_boolparam_collision_handling_enabled        =2;
        sim_boolparam_distance_handling_enabled         =3;
        sim_boolparam_ik_handling_enabled               =4;
        sim_boolparam_gcs_handling_enabled              =5;
        sim_boolparam_dynamics_handling_enabled         =6;
        sim_boolparam_joint_motion_handling_enabled     =7;
        sim_boolparam_path_motion_handling_enabled      =8;
        sim_boolparam_proximity_sensor_handling_enabled =9;
        sim_boolparam_vision_sensor_handling_enabled    =10;
        sim_boolparam_mill_handling_enabled             =11;
        sim_boolparam_browser_visible                   =12;
        sim_boolparam_scene_and_model_load_messages     =13;
        sim_reserved0                                   =14;
        sim_boolparam_shape_textures_are_visible        =15;
        sim_boolparam_display_enabled                   =16;
        sim_boolparam_infotext_visible                  =17;
        sim_boolparam_statustext_open                   =18;
        sim_boolparam_fog_enabled                       =19;
        sim_boolparam_rml2_available                    =20;
        sim_boolparam_rml4_available                    =21;
        sim_boolparam_mirrors_enabled                   =22;
        sim_boolparam_aux_clip_planes_enabled           =23;
        sim_boolparam_full_model_copy_from_api          =24;
        sim_boolparam_realtime_simulation               =25;
        sim_boolparam_force_show_wireless_emission      =27;
        sim_boolparam_force_show_wireless_reception     =28;
        sim_boolparam_video_recording_triggered         =29;
        sim_boolparam_threaded_rendering_enabled        =32;
        sim_boolparam_fullscreen                        =33;
        sim_boolparam_headless                          =34;
        sim_boolparam_hierarchy_toolbarbutton_enabled   =35;
        sim_boolparam_browser_toolbarbutton_enabled     =36;
        sim_boolparam_objectshift_toolbarbutton_enabled =37;
        sim_boolparam_objectrotate_toolbarbutton_enabled=38;
        sim_boolparam_force_calcstruct_all_visible      =39;
        sim_boolparam_force_calcstruct_all              =40;
        sim_boolparam_exit_request                      =41;
        sim_boolparam_play_toolbarbutton_enabled        =42;
        sim_boolparam_pause_toolbarbutton_enabled       =43;
        sim_boolparam_stop_toolbarbutton_enabled        =44;
        sim_boolparam_waiting_for_trigger       =45;


        % Integer parameters
        sim_intparam_error_report_mode      =0;
        sim_intparam_program_version        =1;
        sim_intparam_instance_count         =2;
        sim_intparam_custom_cmd_start_id    =3;
        sim_intparam_compilation_version    =4;
        sim_intparam_current_page           =5;
        sim_intparam_flymode_camera_handle  =6;
        sim_intparam_dynamic_step_divider   =7;
        sim_intparam_dynamic_engine         =8;
        sim_intparam_server_port_start      =9;
        sim_intparam_server_port_range      =10;
        sim_intparam_visible_layers         =11;
        sim_intparam_infotext_style         =12;
        sim_intparam_settings               =13;
        sim_intparam_edit_mode_type         =14;
        sim_intparam_server_port_next       =15;
        sim_intparam_qt_version             =16;
        sim_intparam_event_flags_read       =17;
        sim_intparam_event_flags_read_clear =18;
        sim_intparam_platform               =19;
        sim_intparam_scene_unique_id        =20;
        sim_intparam_work_thread_count      =21;
        sim_intparam_mouse_x                =22;
        sim_intparam_mouse_y                =23;
        sim_intparam_core_count             =24;
        sim_intparam_work_thread_calc_time_ms =25;
        sim_intparam_idle_fps               =26;
        sim_intparam_prox_sensor_select_down =27;
        sim_intparam_prox_sensor_select_up  =28;
        sim_intparam_stop_request_counter   =29;
        sim_intparam_program_revision       =30;
        sim_intparam_mouse_buttons          =31;
        sim_intparam_dynamic_warning_disabled_mask =32;
        sim_intparam_simulation_warning_disabled_mask =33;
        sim_intparam_scene_index            =34;
        sim_intparam_motionplanning_seed    =35;
        sim_intparam_speedmodifier          =36;

        % Float parameters
        sim_floatparam_rand                 =0;
        sim_floatparam_simulation_time_step =1;
        sim_floatparam_stereo_distance      =2;

        % String parameters
        sim_stringparam_application_path    =0;
        sim_stringparam_video_filename      =1;
        sim_stringparam_app_arg1            =2;
        sim_stringparam_app_arg2            =3;
        sim_stringparam_app_arg3            =4;
        sim_stringparam_app_arg4            =5;
        sim_stringparam_app_arg5            =6;
        sim_stringparam_app_arg6            =7;
        sim_stringparam_app_arg7            =8;
        sim_stringparam_app_arg8            =9;
        sim_stringparam_app_arg9            =10;
        sim_stringparam_scene_path_and_name =13;

        % Array parameters
        sim_arrayparam_gravity          =0;
        sim_arrayparam_fog              =1;
        sim_arrayparam_fog_color        =2;
        sim_arrayparam_background_color1=3;
        sim_arrayparam_background_color2=4;
        sim_arrayparam_ambient_light    =5;
        sim_arrayparam_random_euler     =6;

        sim_objintparam_visibility_layer= 10;
        sim_objfloatparam_abs_x_velocity= 11;
        sim_objfloatparam_abs_y_velocity= 12;
        sim_objfloatparam_abs_z_velocity= 13;
        sim_objfloatparam_abs_rot_velocity= 14;
        sim_objfloatparam_objbbox_min_x= 15;
        sim_objfloatparam_objbbox_min_y= 16;
        sim_objfloatparam_objbbox_min_z= 17;
        sim_objfloatparam_objbbox_max_x= 18;
        sim_objfloatparam_objbbox_max_y= 19;
        sim_objfloatparam_objbbox_max_z= 20;
        sim_objfloatparam_modelbbox_min_x= 21;
        sim_objfloatparam_modelbbox_min_y= 22;
        sim_objfloatparam_modelbbox_min_z= 23;
        sim_objfloatparam_modelbbox_max_x= 24;
        sim_objfloatparam_modelbbox_max_y= 25;
        sim_objfloatparam_modelbbox_max_z= 26;
        sim_objintparam_collection_self_collision_indicator= 27;
        sim_objfloatparam_transparency_offset= 28;
        sim_objintparam_child_role= 29;
        sim_objintparam_parent_role= 30;
        sim_objintparam_manipulation_permissions= 31;
        sim_objintparam_illumination_handle= 32;

        sim_visionfloatparam_near_clipping= 1000;
        sim_visionfloatparam_far_clipping= 1001;
        sim_visionintparam_resolution_x= 1002;
        sim_visionintparam_resolution_y= 1003;
        sim_visionfloatparam_perspective_angle= 1004;
        sim_visionfloatparam_ortho_size= 1005;
        sim_visionintparam_disabled_light_components= 1006;
        sim_visionintparam_rendering_attributes= 1007;
        sim_visionintparam_entity_to_render= 1008;
        sim_visionintparam_windowed_size_x= 1009;
        sim_visionintparam_windowed_size_y= 1010;
        sim_visionintparam_windowed_pos_x= 1011;
        sim_visionintparam_windowed_pos_y= 1012;
        sim_visionintparam_pov_focal_blur= 1013;
        sim_visionfloatparam_pov_blur_distance= 1014;
        sim_visionfloatparam_pov_aperture= 1015;
        sim_visionintparam_pov_blur_sampled= 1016;
        sim_visionintparam_render_mode= 1017;

        sim_jointintparam_motor_enabled= 2000;
        sim_jointintparam_ctrl_enabled= 2001;
        sim_jointfloatparam_pid_p= 2002;
        sim_jointfloatparam_pid_i= 2003;
        sim_jointfloatparam_pid_d= 2004;
        sim_jointfloatparam_intrinsic_x= 2005;
        sim_jointfloatparam_intrinsic_y= 2006;
        sim_jointfloatparam_intrinsic_z= 2007;
        sim_jointfloatparam_intrinsic_qx= 2008;
        sim_jointfloatparam_intrinsic_qy= 2009;
        sim_jointfloatparam_intrinsic_qz= 2010;
        sim_jointfloatparam_intrinsic_qw= 2011;
        sim_jointfloatparam_velocity= 2012;
        sim_jointfloatparam_spherical_qx= 2013;
        sim_jointfloatparam_spherical_qy= 2014;
        sim_jointfloatparam_spherical_qz= 2015;
        sim_jointfloatparam_spherical_qw= 2016;
        sim_jointfloatparam_upper_limit= 2017;
        sim_jointfloatparam_kc_k= 2018;
        sim_jointfloatparam_kc_c= 2019;
        sim_jointfloatparam_ik_weight= 2021;
        sim_jointfloatparam_error_x= 2022;
        sim_jointfloatparam_error_y= 2023;
        sim_jointfloatparam_error_z= 2024;
        sim_jointfloatparam_error_a= 2025;
        sim_jointfloatparam_error_b= 2026;
        sim_jointfloatparam_error_g= 2027;
        sim_jointfloatparam_error_pos= 2028;
        sim_jointfloatparam_error_angle= 2029;
        sim_jointintparam_velocity_lock= 2030;
        sim_jointintparam_vortex_dep_handle= 2031;
        sim_jointfloatparam_vortex_dep_multiplication= 2032;
        sim_jointfloatparam_vortex_dep_offset= 2033;

        sim_shapefloatparam_init_velocity_x= 3000;
        sim_shapefloatparam_init_velocity_y= 3001;
        sim_shapefloatparam_init_velocity_z= 3002;
        sim_shapeintparam_static= 3003;
        sim_shapeintparam_respondable= 3004;
        sim_shapefloatparam_mass= 3005;
        sim_shapefloatparam_texture_x= 3006;
        sim_shapefloatparam_texture_y= 3007;
        sim_shapefloatparam_texture_z= 3008;
        sim_shapefloatparam_texture_a= 3009;
        sim_shapefloatparam_texture_b= 3010;
        sim_shapefloatparam_texture_g= 3011;
        sim_shapefloatparam_texture_scaling_x= 3012;
        sim_shapefloatparam_texture_scaling_y= 3013;
        sim_shapeintparam_culling= 3014;
        sim_shapeintparam_wireframe= 3015;
        sim_shapeintparam_compound= 3016;
        sim_shapeintparam_convex= 3017;
        sim_shapeintparam_convex_check= 3018;
        sim_shapeintparam_respondable_mask= 3019;
        sim_shapefloatparam_init_velocity_a= 3020;
        sim_shapefloatparam_init_velocity_b= 3021;
        sim_shapefloatparam_init_velocity_g= 3022;
        sim_shapestringparam_color_name= 3023;
        sim_shapeintparam_edge_visibility= 3024;
        sim_shapefloatparam_shading_angle= 3025;
        sim_shapefloatparam_edge_angle= 3026;
        sim_shapeintparam_edge_borders_hidden= 3027;

        sim_proxintparam_ray_invisibility= 4000;

        sim_forcefloatparam_error_x= 5000;
        sim_forcefloatparam_error_y= 5001;
        sim_forcefloatparam_error_z= 5002;
        sim_forcefloatparam_error_a= 5003;
        sim_forcefloatparam_error_b= 5004;
        sim_forcefloatparam_error_g= 5005;
        sim_forcefloatparam_error_pos= 5006;
        sim_forcefloatparam_error_angle= 5007;

        sim_lightintparam_pov_casts_shadows= 8000;

        sim_cameraintparam_disabled_light_components= 9000;
        sim_camerafloatparam_perspective_angle= 9001;
        sim_camerafloatparam_ortho_size= 9002;
        sim_cameraintparam_rendering_attributes= 9003;
        sim_cameraintparam_pov_focal_blur= 9004;
        sim_camerafloatparam_pov_blur_distance= 9005;
        sim_camerafloatparam_pov_aperture= 9006;
        sim_cameraintparam_pov_blur_samples= 9007;

        sim_dummyintparam_link_type= 10000;

        sim_mirrorfloatparam_width= 12000;
        sim_mirrorfloatparam_height= 12001;
        sim_mirrorfloatparam_reflectance= 12002;
        sim_mirrorintparam_enable= 12003;

        sim_pplanfloatparam_x_min= 20000;
        sim_pplanfloatparam_x_range= 20001;
        sim_pplanfloatparam_y_min= 20002;
        sim_pplanfloatparam_y_range= 20003;
        sim_pplanfloatparam_z_min= 20004;
        sim_pplanfloatparam_z_range= 20005;
        sim_pplanfloatparam_delta_min= 20006;
        sim_pplanfloatparam_delta_range= 20007;

        sim_mplanintparam_nodes_computed= 25000;
        sim_mplanintparam_prepare_nodes= 25001;
        sim_mplanintparam_clear_nodes= 25002;

        % User interface elements
        sim_gui_menubar                     =1;
        sim_gui_popups                      =2;
        sim_gui_toolbar1                    =4;
        sim_gui_toolbar2                    =8;
        sim_gui_hierarchy                   =16;
        sim_gui_infobar                     =32;
        sim_gui_statusbar                   =64;
        sim_gui_scripteditor                =128;
        sim_gui_scriptsimulationparameters  =256;
        sim_gui_dialogs                     =512;
        sim_gui_browser                     =1024;
        sim_gui_all                         =65535;


        % Joint modes
        sim_jointmode_passive       =0;
        sim_jointmode_motion        =1;
        sim_jointmode_ik            =2;
        sim_jointmode_ikdependent   =3;
        sim_jointmode_dependent     =4;
        sim_jointmode_force         =5;


        % Navigation and selection modes with the mouse.
        sim_navigation_passive                  =0;
        sim_navigation_camerashift              =1;
        sim_navigation_camerarotate             =2;
        sim_navigation_camerazoom               =3;
        sim_navigation_cameratilt               =4;
        sim_navigation_cameraangle              =5;
        sim_navigation_camerafly                =6;
        sim_navigation_objectshift              =7;
        sim_navigation_objectrotate             =8;
        sim_navigation_reserved2                =9;
        sim_navigation_reserved3                =10;
        sim_navigation_jointpathtest            =11;
        sim_navigation_ikmanip                  =12;
        sim_navigation_objectmultipleselection  =13;

        sim_navigation_reserved4                =256;
        sim_navigation_clickselection           =512;
        sim_navigation_ctrlselection            =1024;
        sim_navigation_shiftselection           =2048;
        sim_navigation_camerazoomwheel          =4096;
        sim_navigation_camerarotaterightbutton  =8192;


        % Remote API message header structure
        simx_headeroffset_crc           =0;
        simx_headeroffset_version       =2;
        simx_headeroffset_message_id    =3;
        simx_headeroffset_client_time   =7;
        simx_headeroffset_server_time   =11;
        simx_headeroffset_scene_id      =15;
        simx_headeroffset_server_state  =17;

        % Remote API command header
        simx_cmdheaderoffset_mem_size       =0;
        simx_cmdheaderoffset_full_mem_size  =4;
        simx_cmdheaderoffset_pdata_offset0  =8;
        simx_cmdheaderoffset_pdata_offset1  =10;
        simx_cmdheaderoffset_cmd            =14;
        simx_cmdheaderoffset_delay_or_split =18;
        simx_cmdheaderoffset_sim_time       =20;
        simx_cmdheaderoffset_status         =24;
        simx_cmdheaderoffset_reserved       =25;


        % Regular operation modes
        simx_opmode_oneshot             =0;
        simx_opmode_blocking            =65536;
        simx_opmode_oneshot_wait        =65536;
        simx_opmode_continuous          =131072;
        simx_opmode_streaming           =131072;

        % Operation modes for heavy data
        simx_opmode_oneshot_split       =196608;
        simx_opmode_continuous_split    =262144;
        simx_opmode_streaming_split     =262144;

        % Special operation modes
        simx_opmode_discontinue         =327680;
        simx_opmode_buffer              =393216;
        simx_opmode_remove              =458752;


        % Command return codes
        simx_return_ok                      =0;
        simx_return_novalue_flag            =1;
        simx_return_timeout_flag            =2;
        simx_return_illegal_opmode_flag     =4;
        simx_return_remote_error_flag       =8;
        simx_return_split_progress_flag     =16;
        simx_return_local_error_flag        =32;
        simx_return_initialize_error_flag   =64;

        % Following for backward compatibility (same as above)
        simx_error_noerror                  =0;
        simx_error_novalue_flag             =1;
        simx_error_timeout_flag             =2;
        simx_error_illegal_opmode_flag      =4;
        simx_error_remote_error_flag        =8;
        simx_error_split_progress_flag      =16;
        simx_error_local_error_flag         =32;
        simx_error_initialize_error_flag    =64;
    end
    
    methods
        function cleanUp(obj)
            obj.pongReceived=false;
            obj.handleFunction('Ping',{0},obj.simxDefaultSubscriber(@obj.pingCallback));
            while not(obj.pongReceived)
                obj.simxSpinOnce();
            end
            obj.handleFunction('DisconnectClient',{obj.clientId},obj.serviceCallTopic);
            
            allKeys=keys(obj.allSubscribers);
            for key=allKeys
                value=obj.allSubscribers(key{1});
                if value('handle')~=obj.defaultSubscriber
                    calllib(obj.libName,'b0_subscriber_delete',value('handle'));
                end
            end
            allKeys=keys(obj.allDedicatedPublishers);
            for key=allKeys
                value=obj.allDedicatedPublishers(key{1});
                calllib(obj.libName,'b0_publisher_delete',value);
            end
%            calllib(obj.libName,'b0_node_delete',obj.node);
            unloadlibrary(obj.libName);
        end
        
        function pingCallback(obj,msg)
            obj.pongReceived=true;
        end

        
        function obj = b0RemoteApi(nodeName,channelName,inactivityToleranceInSec,setupSubscribersAsynchronously,hfile)
            addpath('./msgpack-matlab/');
            obj.libName = 'b0';
            obj.nodeName='b0RemoteApi_matlabClient';
            obj.channelName='b0RemoteApi';
            obj.inactivityToleranceInSec=60;
            obj.setupSubscribersAsynchronously=false;
            if nargin>=1
                obj.nodeName=nodeName;
            end
            if nargin>=2
                obj.channelName=channelName;
            end
            if nargin>=3
                obj.inactivityToleranceInSec=inactivityToleranceInSec;
            end
            if nargin>=4
                obj.setupSubscribersAsynchronously=setupSubscribersAsynchronously;
            end
            obj.serviceCallTopic=strcat(obj.channelName,'SerX');
            obj.defaultPublisherTopic=strcat(obj.channelName,'SubX');
            obj.defaultSubscriberTopic=strcat(obj.channelName,'PubX');
            obj.nextDefaultSubscriberHandle=2;
            obj.nextDedicatedPublisherHandle=500;
            obj.nextDedicatedSubscriberHandle=1000;
            if ~libisloaded(obj.libName)
                if nargin>=5
                    obj.hFile = hfile;
                    loadlibrary(obj.libName,obj.hFile);
                else
                    loadlibrary(obj.libName,@b0RemoteApiProto);
                end
            end
            obj.node = calllib(obj.libName,'b0_node_new',libpointer('int8Ptr',[uint8(obj.nodeName) 0]));
            chars = ['a':'z' 'A':'Z' '0':'9'];
            n = randi(numel(chars),[1 10]);
            obj.clientId= chars(n);
            

            tmp = libpointer('int8Ptr',[uint8(obj.serviceCallTopic) 0]);
            obj.serviceClient = calllib(obj.libName,'b0_service_client_new_ex',obj.node,tmp,1,1);

            tmp = libpointer('int8Ptr',[uint8(obj.defaultPublisherTopic) 0]);
            obj.defaultPublisher = calllib(obj.libName,'b0_publisher_new_ex',obj.node,tmp,1,1);

            tmp = libpointer('int8Ptr',[uint8(obj.defaultSubscriberTopic) 0]);
            obj.defaultSubscriber = calllib(obj.libName,'b0_subscriber_new_ex',obj.node,tmp,[],1,1); % We will poll the socket
            
            
            disp(char(10));
            disp(strcat('  Running B0 Remote API client with channel name [',obj.channelName,']'));
            disp('  make sure that: 1) the B0 resolver is running');
            disp('                  2) V-REP is running the B0 Remote API server with the same channel name');
            disp('  Initializing...');
            disp(char(10));
            try
                calllib(obj.libName,'b0_node_init',obj.node);
            catch me
                obj.cleanUp();
                rethrow(me);
            end
            obj.handleFunction('inactivityTolerance',{obj.inactivityToleranceInSec},obj.serviceCallTopic);
            disp(char(10));
            disp('  Connected!');
            disp(char(10));
            obj.allSubscribers=containers.Map;
            obj.allDedicatedPublishers=containers.Map;
        end

        function delete(obj)
            obj.cleanUp();
        end
        

        function topic = simxDefaultPublisher(obj)
            topic = obj.defaultPublisherTopic;
        end

        function topic = simxCreatePublisher(obj,dropMessages)
            if not(exist('dropMessages'))
                dropMessages=false;
            end
            topic=strcat(obj.channelName,'Sub',num2str(obj.nextDedicatedPublisherHandle),obj.clientId);
            obj.nextDedicatedPublisherHandle=obj.nextDedicatedPublisherHandle+1;
            tmp = libpointer('int8Ptr',[uint8(topic) 0]);
            pub = calllib(obj.libName,'b0_publisher_new_ex',obj.node,tmp,0,1);
            calllib(obj.libName,'b0_publisher_init',pub);
            obj.allDedicatedPublishers(topic)=pub;
            obj.handleFunction('createSubscriber',{topic,dropMessages},obj.serviceCallTopic);
        end

        function topic = simxDefaultSubscriber(obj,cb,publishInterval)
            if not(exist('publishInterval'))
                publishInterval=1;
            end
            topic=strcat(obj.channelName,'Pub',num2str(obj.nextDefaultSubscriberHandle),obj.clientId);
            obj.nextDefaultSubscriberHandle=obj.nextDefaultSubscriberHandle+1;
            theMap=containers.Map;
            theMap('handle')=obj.defaultSubscriber;
            theMap('cb')=cb;
            theMap('dropMessages')=false;
            obj.allSubscribers(topic)=theMap;
            channel=obj.serviceCallTopic;
            if obj.setupSubscribersAsynchronously
                channel=obj.defaultPublisherTopic;
            end
            obj.handleFunction('setDefaultPublisherPubInterval',{topic,publishInterval},channel);
        end
            
        function topic = simxCreateSubscriber(obj,cb,publishInterval,dropMessages)
            if not(exist('publishInterval'))
                publishInterval=1;
            end
            if not(exist('dropMessages'))
                dropMessages=false;
            end
            topic=strcat(obj.channelName,'Pub',num2str(obj.nextDedicatedSubscriberHandle),obj.clientId);
            obj.nextDedicatedSubscriberHandle=obj.nextDedicatedSubscriberHandle+1;
            tmp = libpointer('int8Ptr',[uint8(topic) 0]);
            sub = calllib(obj.libName,'b0_subscriber_new_ex',obj.node,tmp,[],0,1); % We will poll the socket
            calllib(obj.libName,'b0_subscriber_init',sub);
            theMap=containers.Map;
            theMap('handle')=sub;
            theMap('cb')=cb;
            theMap('dropMessages')=dropMessages;
            obj.allSubscribers(topic)=theMap;
            channel=obj.serviceCallTopic;
            if obj.setupSubscribersAsynchronously
                channel=obj.defaultPublisherTopic;
            end
            obj.handleFunction('createPublisher',{topic,publishInterval},channel);
        end
  
        function topic = simxServiceCall(obj)
            topic = obj.serviceCallTopic;
        end

        
        function simxSpin(obj)
            %calllib(obj.libName,'b0_node_spin',obj.node);
            while true
                obj.simxSpinOnce();
            end
        end
        
        function simxSpinOnce(obj)
            defaultSubscriberAlreadyProcessed=false;
            allKeys=keys(obj.allSubscribers);
            for key=allKeys
                value=obj.allSubscribers(key{1});
                retData=[];
                if (value('handle')~=obj.defaultSubscriber) || not(defaultSubscriberAlreadyProcessed)
                    defaultSubscriberAlreadyProcessed=defaultSubscriberAlreadyProcessed || (value('handle')==obj.defaultSubscriber);
                    while calllib(obj.libName,'b0_subscriber_poll',value('handle'),0)>0
                        if not(isempty(retData))
                            calllib(obj.libName,'b0_buffer_delete',retData);
                            retData=[];
                        end
                        retData = libpointer('uint8PtrPtr');
                        retSize = libpointer('uint64Ptr',uint64(0));
                        [retData subClient retSize]=calllib(obj.libName,'b0_subscriber_read',value('handle'),retSize);
                        retData.setdatatype('uint8Ptr',1,retSize);
                        if not(value('dropMessages'))
                            obj.handleReceivedMessage(retData.value);
                            calllib(obj.libName,'b0_buffer_delete',retData);
                            retData=[];
                        end
                    end
                    if value('dropMessages') && not(isempty(retData))
                        obj.handleReceivedMessage(retData.value);
                        calllib(obj.libName,'b0_buffer_delete',retData);
                        retData=[];
                    end
                end
            end
        end
        
        
        function handleReceivedMessage(obj,data)
            msg = parsemsgpack(data);
            kk=msg(1);
            k=kk{1};
            if isKey(obj.allSubscribers,k)
                value=obj.allSubscribers(k);
                cbMsg=msg(2);
                if length(cbMsg)==1
                    cbMsg=[cbMsg,[]];
                end
                cb=value('cb');
                cb(cbMsg{1});
            end
        end
        
        function ret = handleFunction(obj,funcName,reqArgs,topic)
            if strcmp(topic,obj.serviceCallTopic)
                packedData = dumpmsgpack({{funcName,obj.clientId,topic,0},reqArgs});
            
                retData = libpointer('uint8PtrPtr');
                retSize = libpointer('uint64Ptr',uint64(0));
                [retData servClient packedData retSize]= calllib(obj.libName,'b0_service_client_call',obj.serviceClient,packedData,length(packedData),retSize);
                if retSize > 0
                    retData.setdatatype('uint8Ptr',1,retSize);
                    returnedData = retData.value;
                    ret = parsemsgpack(returnedData);
                    if length(ret)<2
                        ret=[ret,[]];
                    end
                else 
                    ret=[];
                end
            else 
                if strcmp(topic,obj.defaultPublisherTopic)
                    packedData = dumpmsgpack({{funcName,obj.clientId,topic,1},reqArgs});
                    calllib(obj.libName,'b0_publisher_publish',obj.defaultPublisher,packedData,length(packedData));
                    ret=[];
                else 
                    if isKey(obj.allSubscribers,topic)
                        val=obj.allSubscribers(topic);
                        packedData=[];
                        if val('handle')==obj.defaultSubscriber
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,2},reqArgs});
                        else
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,4},reqArgs});
                        end
                        if obj.setupSubscribersAsynchronously
                            calllib(obj.libName,'b0_publisher_publish',obj.defaultPublisher,packedData,length(packedData));
                        else
                            retData = libpointer('uint8PtrPtr');
                            retSize = libpointer('uint64Ptr',uint64(0));
                            [retData servClient packedData retSize]= calllib(obj.libName,'b0_service_client_call',obj.serviceClient,packedData,length(packedData),retSize);
                        end
                        ret=[];
                    else 
                        if isKey(obj.allDedicatedPublishers,topic)
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,3},reqArgs});
                            calllib(obj.libName,'b0_publisher_publish',obj.allDedicatedPublishers,packedData,length(packedData));
                        else
                            disp('B0 Remote API error: invalid topic');
                        end
                        ret=[];
                    end
                end
            end
        end
        

        function ret = simxGetTimeInMs(obj)
            ret = calllib(obj.libName,'b0_node_time_usec',obj.node)/1000;
        end
        
        function simxSleep(obj,durationInMs)
            startT=obj.simxGetTimeInMs();
            while obj.simxGetTimeInMs()<startT+durationInMs
            end
        end
        
        function simxSynchronous(obj,enable)
            args = {enable};
            obj.handleFunction('Synchronous',args,obj.serviceCallTopic);
        end
        
        function simxSynchronousTrigger(obj)
            args = {0};
            obj.handleFunction('SynchronousTrigger',args,obj.defaultPublisherTopic);
        end
        
        function simxGetSimulationStepDone(obj,topic)
            if isKey(obj.allSubscribers,topic)
                reqArgs = {0};
                obj.handleFunction('GetSimulationStepDone',reqArgs,topic);
            else
                disp('B0 Remote API error: invalid topic');
            end
        end
        
        function simxGetSimulationStepStarted(obj,topic)
            if isKey(obj.allSubscribers,topic)
                reqArgs = {0};
                obj.handleFunction('GetSimulationStepStarted',reqArgs,topic);
            else
                disp('B0 Remote API error: invalid topic');
            end
        end
            
           
    
        % ------------------------------
        % Add your custom function here:
        % ------------------------------
        
        function ret = simxGetObjectHandle(obj,objectName,cbId)
            args = {objectName};
            ret = obj.handleFunction('GetObjectHandle',args,cbId);
        end
        
        function ret = simxGetVisionSensorImage(obj,objectHandle,greyScale,cbId)
            args = {objectHandle,greyScale};
            ret = obj.handleFunction('GetVisionSensorImage',args,cbId);
        end
        
        function ret = simxSetVisionSensorImage(obj,objectHandle,greyScale,img,cbId)
            args = {objectHandle,greyScale,img};
            ret = obj.handleFunction('SetVisionSensorImage',args,cbId);
        end
        
        function ret = simxAddStatusbarMessage(obj,msg,cbId)
            args = {msg};
            ret = obj.handleFunction('AddStatusbarMessage',args,cbId);
        end
        
        function ret = simxGetObjectPosition(obj,objHandle,relObjHandle,cbId)
            args = {objHandle,relObjHandle};
            ret = obj.handleFunction('GetObjectPosition',args,cbId);
        end
        
        function ret = simxStartSimulation(obj,cbId)
            args = {0};
            ret = obj.handleFunction('StartSimulation',args,cbId);
        end
        
        function ret = simxStopSimulation(obj,cbId)
            args = {0};
            ret = obj.handleFunction('StopSimulation',args,cbId);
        end
    end
end
