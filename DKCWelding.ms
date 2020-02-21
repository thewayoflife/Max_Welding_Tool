/* DKC */


/* Delete dialog */
try(destroyDialog ::WeldingTool)catch()


-- Tool design --
rollout WeldingTool "DKC Welding"
(
	/* Numbers represent height position. #() is for an empty array */
	local grA = 10
	local grB = 110
	local grC = 260
	local new_weld = #()

	/* Settings */
	groupbox gr_settings "Settings" pos:[10,grA] width:180 height:90
	
	label lb_thickness "Thickness:" pos:[19,grA+20]
	spinner ui_thickness "" fieldwidth:55 range:[0,1e6,4.0] type:#worldUnits pos:[115,grA+20]
	label lb_sides "Side Segments:" pos:[19,grA+40]
	spinner ui_sides "" fieldwidth:55 range:[3,1e6,8] type:#integer pos:[115,grA+40]
	label lb_angle "Angle:" pos:[19,grA+60]
	spinner ui_angle fieldwidth:55 range:[-180.0,180.0,0.0] type:#float pos:[115,grA+60]
	
	/* Bead Settings */
	groupbox gr_bead_settings "Bead Settings" pos:[10,grB] width:180 height:160

	label lb_displace_strength "Strength:" pos:[19,grB+30]
	spinner ui_displace_strength "" fieldwidth:55 range:[-1e6,1e6,2.5] type:#worldUnits pos:[115,grB+30]
	label lb_cellular_size "Size:" pos:[19,grB+50]
	spinner ui_cellular_size "" fieldwidth:55 range:[0.0001,1e6,8.0] type:#float pos:[115,grB+50]
	label lb_cellular_spread "Spread:" pos:[19,grB+70]
	spinner ui_cellular_spread "" fieldwidth:55 range:[0.0001,1e6,0.2] type:#float pos:[115,grB+70]
	label lb_cellular_thresholds_low "Threshold Low:" pos:[19,grB+90]
	spinner ui_cellular_threshold_low fieldwidth:55 range:[0.0,1.0,0.0] type:#float pos:[115,grB+90]
	label lb_cellular_thresholds_mid "Threshold Mid:" pos:[19,grB+110]
	spinner ui_cellular_threshold_mid fieldwidth:55 range:[0.0,1.0,0.5] type:#float pos:[115,grB+110]
	label lb_cellular_thresholds_high "Threshold High" pos:[19,grB+130]
	spinner ui_cellular_threshold_high fieldwidth:55 range:[0.0,1.0,1.0] type:#float pos:[115,grB+130]
	
	/* Button Generate */
	button ui_generate_weld "Generate Intersecting Weld" width:180 height:25 pos:[10,grC+30]



 -- Functions --


	/* Check if nodes are Geometry or Shape */
	fn valid_objects nodes =
	(
		for n in nodes do
		(
			if superClassOf n != GeometryClass and superClassOf n != Shape do 
			(
				local msg = "Error!\nInvalid object found in selection: " + n.name + "\n"
				msg += "Objects must be of type Geometry or Shape."
				messagebox msg
				return false
			)
		)
		return true
	)

	/* Get Poly from snapshot obj */
	fn get_poly_snapshot obj =
	(
		(convertToPoly (snapshot obj))
	)

	/* Set object property value */
	fn set_property obj prop val =
	(
		if isproperty obj prop do setproperty obj prop val
	)

	/* Set spline property value */
	fn set_spline_property prop val = 
	(
		undo on 
		(
			for obj in selection where superclassof obj.baseobject == shape do
			(
				set_property obj prop val
			)
		)
	)

	/* mod_int represents which instance of the modifier to change. 1 - first instance, 2 - second instance, itd‚*/
	fn set_modifier_property classname mod_int prop val =
	(
		undo on 
		(
			for i = 1 to selection.count do
			(
				local mods = for m in selection[i].modifiers where (classOf m == classname) collect m
				if mods.count >= mod_int do set_property mods[mod_int] prop val
			)
		)
	)

	/* Set property map value */
	fn set_map_property classname prop val =	
	(
		undo on 
		(
			for i = 1 to selection.count do
			(
				for m in selection[i].modifiers where (classOf m == Displace) and (classof m.map == classname) do
				(
					set_property m.map prop val
				)
			)
		)
	)

	/* Convert edge selection to spline */
	fn convert_edge_selection_to_weld obj = 
	(
		local edges = polyop.getEdgeSelection obj
		polyop.createShape obj edges name:"the_weld" smooth:off
		
		local the_weld = getNodeByName "the_weld"
		the_weld.name = uniqueName "Weld_"
		the_weld.wirecolor = red
		the_weld.baseObject.render_renderable = true
		the_weld.baseObject.render_displayRenderMesh = true
		the_weld.baseObject.render_mapcoords = true
 		the_weld.baseObject.render_thickness = ui_thickness.value
 		the_weld.baseObject.render_sides = ui_sides.value

 		return the_weld
	)
	
	/* Define weld type values */
	fn set_weld_type obj =
	(		
		local the_map = Cellular size:ui_cellular_size.value spread:ui_cellular_spread.value lowThresh:ui_cellular_threshold_low.value midThresh:ui_cellular_threshold_mid.value highThresh:ui_cellular_threshold_high.value
		the_map.coords.coordType = 0 -- Object XYZ
		addModifier obj (Displace map:the_map strength:ui_displace_strength.value lumCenterEnable:true useMap:true)
		append new_weld obj
	) 

	/* Pick objects to weld */
	fn create_intersecting_weld =
	(
		local obj_to_weld = undefined -- main object everything is getting welded to
		local sub_objs_to_weld = #()
		local weld_obj = undefined
		local nodes = getCurrentSelection()
		new_weld = #()

		if not valid_objects nodes do 
		(
			return false
		)
		if nodes.count <= 1 do
		(
			messagebox "Error!\nPlease select 2 or more objects."
			return false
		)

		setCommandPanelTaskMode #create 
		disableSceneRedraw()

		with undo off
		(
			obj_to_weld = get_poly_snapshot nodes[1]
			sub_objs_to_weld = for i = 2 to nodes.count collect get_poly_snapshot nodes[i]

			ProBoolean.createBooleanObjects obj_to_weld sub_objs_to_weld 2 1 0
			ProBoolean.SetMakeQuad obj_to_weld true
			weld_obj = convertToPoly obj_to_weld
			weld_spl = convert_edge_selection_to_weld weld_obj
			set_weld_type weld_spl
	 		delete weld_obj
		)

		select new_weld
		enableSceneRedraw()
		forceCompleteRedraw()
	)



 -- Actions --

	on ui_generate_weld pressed do create_intersecting_weld()
	
	on ui_thickness changed val do set_spline_property #thickness val
	on ui_sides changed val do set_spline_property #sides val
	on ui_angle changed val do set_spline_property #angle val

	on ui_displace_strength changed val do set_modifier_property Displace 1 #strength val

	on ui_cellular_size changed val do set_map_property Cellular #size val
	on ui_cellular_spread changed val do set_map_property Cellular #spread val
	on ui_cellular_threshold_low changed val do set_map_property Cellular #lowThresh val
	on ui_cellular_threshold_mid changed val do set_map_property Cellular #midThresh val
	on ui_cellular_threshold_high changed val do set_map_property Cellular #highThresh val
	

) -- end of rollout

/* Create dialog */
createDialog WeldingTool 200 335
