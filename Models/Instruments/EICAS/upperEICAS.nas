# ==============================================================================
# For 737-800 by Michael Soitanen
# Updated and Expanded according to FCOM by Jonathan Redpath
# ==============================================================================

var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}

var upperEICAS_canvas = nil;
var upperEICAS_display = nil;

var canvas_upperEICAS = {
	new: func(canvas_group)
	{
		var m = { parents: [canvas_upperEICAS] };
		var upperEICAS = canvas_group;
		var font_mapper = func(family, weight)
		{
			if( family == "'Liberation Sans'" and weight == "normal" )
				return "LiberationFonts/LiberationSans-Regular.ttf";
		};
		
		canvas.parsesvg(upperEICAS, "Aircraft/737-Next-Generation/Models/Instruments/EICAS/upperEICAS.svg", {'font-mapper': font_mapper});
		
		var svg_keys = ["engine0N1","engine0N1Decimal","engine1N1","engine1N1Decimal",
		"engine0rev","engine1rev",
		"EGT_0","EGT_1","needleEGT_0","needleEGT_1","ff_0","ff_1",
		"needleN1_0","needleN1_1","tat",
		"tank1Thousand","tank1Decimal","tank2Thousand","tank2Decimal","tankCtrThousand","tankCtrDecimal",
		"tank1Line","tank2Line","tankCtrLine","engFailL","engFailR","TAI-l","TAI-r","thrustSetting","N1limit1","N1limit2"];
		foreach(var key; svg_keys) {
			m[key] = upperEICAS.getElementById(key);
		}
                 m.timers = [];
 
		return m;
	},
          newMFD: func()
 	{
 		me.update_timer = maketimer(0.1, func me.update() );
 		
 		me.update_timer.start();
        },
	update: func()
	{
		var n1_0 = getprop("/engines/engine[0]/n1") + 0.05;
		var n1_1 = getprop("/engines/engine[1]/n1") + 0.05;
		var n2_0 = getprop("/engines/engine[0]/n2");
		var n2_1 = getprop("/engines/engine[1]/n2");
		var egt_0 = getprop("/engines/engine[0]/egt-actual");
		var egt_1 = getprop("/engines/engine[1]/egt-actual");
		var fuel_flow_0 = getprop("/engines/engine[0]/fuel-flow_pph")*0.4536/1000;
		var fuel_flow_1 = getprop("/engines/engine[1]/fuel-flow_pph")*0.4536/1000;
		var tat = roundToNearest(getprop("/fdm/jsbsim/propulsion/tat-c"),1);
		var tank1 = roundToNearest(getprop("/consumables/fuel/tank[0]/level-kg"), 20);
		var tank2 = roundToNearest(getprop("/consumables/fuel/tank[1]/level-kg"), 20);
		var tankCtr = roundToNearest(getprop("/consumables/fuel/tank[2]/level-kg"), 20);
		
		var n1_0_int = int(n1_0);
		var n1_0_dec = int(10*math.mod(n1_0,1));
		var n1_1_int = int(n1_1);
		var n1_1_dec = int(10*math.mod(n1_1,1));

		var reverser_0 = getprop("/engines/engine[0]/reverser-pos-norm");
		var reverser_1 = getprop("/engines/engine[1]/reverser-pos-norm");
		var cutoff_0 = getprop("/controls/engines/engine[0]/cutoff");
		var cutoff_1 = getprop("/controls/engines/engine[1]/cutoff");
		var starter_0 = getprop("/controls/engines/engine[0]/starter");
		var starter_1 = getprop("/controls/engines/engine[1]/starter");
		var serviceable_0 = getprop("/sim/failure-manager/engines/engine[0]/serviceable");
		var serviceable_1 = getprop("/sim/failure-manager/engines/engine[1]/serviceable");
		var antiiceL = getprop("controls/anti-ice/engine[0]/carb-heat");
		var antiiceR = getprop("controls/anti-ice/engine[1]/carb-heat");
		
		var thrustStg = getprop("/it-autoflight/input/thrustStg");
		
		me["engine0N1"].setText(sprintf("%s", n1_0_int));
		me["engine0N1Decimal"].setText(sprintf("%s", n1_0_dec));
		me["engine1N1"].setText(sprintf("%s", n1_1_int));
		me["engine1N1Decimal"].setText(sprintf("%s", n1_1_dec));
		me["needleN1_0"].setRotation(n1_0*1.965*D2R);
		me["needleN1_1"].setRotation(n1_1*1.965*D2R);

		me["EGT_0"].setText(sprintf("%3.0f",egt_0));
		me["EGT_1"].setText(sprintf("%3.0f",egt_1));
		me["needleEGT_0"].setRotation(egt_0*0.2015*D2R);
		me["needleEGT_1"].setRotation(egt_1*0.2015*D2R);

		me["ff_0"].setText(sprintf("%01.2f",fuel_flow_0));
		me["ff_1"].setText(sprintf("%01.2f",fuel_flow_1));

		me["tat"].setText(sprintf("%+2.0f", tat));
		
		if (antiiceL) {
			me["TAI-l"].show();
		} else {
			me["TAI-l"].hide();
		}
		
		if (antiiceR) {
			me["TAI-r"].show();
		} else {
			me["TAI-r"].hide();
		}
		
		if (thrustStg == "G/A") {
			me["thrustSetting"].setText(sprintf("%s","G/A"));
		} else if (thrustStg == "TO") {
			me["thrustSetting"].setText(sprintf("%s","TO"));
		} else {
            me["thrustSetting"].setText(sprintf("%s","CON"));
        }
		
		if (n2_0 < 50 and cutoff_0 == 0 and starter_0 == 0 and !serviceable_0) {
			me["engFailL"].show();
		} else {
			me["engFailL"].hide();
		}
		
		if (n2_1 < 50 and cutoff_1 == 0 and starter_1 == 0 and !serviceable_1) {
			me["engFailR"].show();
		} else {
			me["engFailR"].hide();
		}
		
		if (tank1 < 1000 ) {
			me["tank1Thousand"].hide();
			me["tank1Decimal"].setText(sprintf("%3.0f",math.mod(tank1,1000)));
		} else {
			me["tank1Thousand"].show();
			me["tank1Thousand"].setText(sprintf("%1.0f",int(tank1/1000)));
			me["tank1Decimal"].setText(sprintf("%03.0f",math.mod(tank1,1000)));
		}
		if (tank2 < 1000 ) {
			me["tank2Thousand"].hide();
			me["tank2Decimal"].setText(sprintf("%3.0f",math.mod(tank2,1000)));
		} else {
			me["tank2Thousand"].show();
			me["tank2Thousand"].setText(sprintf("%1.0f",int(tank2/1000)));
			me["tank2Decimal"].setText(sprintf("%03.0f",math.mod(tank2,1000)));
		}
		if (tankCtr < 1000 ) {
			me["tankCtrThousand"].hide();
			me["tankCtrDecimal"].setText(sprintf("%3.0f",math.mod(tankCtr,1000)));
		} else {
			me["tankCtrThousand"].show();
			me["tankCtrThousand"].setText(sprintf("%1.0f",int(tankCtr/1000)));
			me["tankCtrDecimal"].setText(sprintf("%03.0f",math.mod(tankCtr,1000)));
		}

		#Drawing nice circles around fuel gauges.
		var tank1Norm = tank1 / 3920;
		var CtrX = 725;
		var CtrY = 967;
		var cmd = 18;
		if (tank1Norm > 0.75) cmd = 22;
		var radius = 78.5;
		var startX = CtrX + math.cos(-150*D2R) * radius;
		var startY = CtrY - math.sin(-150*D2R) * radius;
		var angle = -tank1Norm * 240 - 150;
		var finishX = CtrX + math.cos(angle*D2R) * radius;
		var finishY = CtrY - math.sin(angle*D2R) * radius;
		me["tank1Line"].setData([2, cmd],[startX, startY, radius, radius, 0, finishX, finishY]);

		var tank2Norm = tank2 / 3920;
		CtrX = 927.857;
		CtrY = 967;
		cmd = 18;
		if (tank2Norm > 0.75) cmd = 22;
		startX = CtrX + math.cos(-150*D2R) * radius;
		startY = CtrY - math.sin(-150*D2R) * radius;
		angle = -tank2Norm * 240 - 150;
		finishX = CtrX + math.cos(angle*D2R) * radius;
		finishY = CtrY - math.sin(angle*D2R) * radius;
		me["tank2Line"].setData([2, cmd],[startX, startY, radius, radius, 0, finishX, finishY]);

		var tankCtrNorm = tankCtr / 13060;
		CtrX = 827.857;
		CtrY = 823.429;
		cmd = 18;
		if (tankCtrNorm > 0.75) cmd = 22;
		startX = CtrX + math.cos(-150*D2R) * radius;
		startY = CtrY - math.sin(-150*D2R) * radius;
		angle = -tankCtrNorm * 240 - 150;
		finishX = CtrX + math.cos(angle*D2R) * radius;
		finishY = CtrY - math.sin(angle*D2R) * radius;
		me["tankCtrLine"].setData([2, cmd],[startX, startY, radius, radius, 0, finishX, finishY]);

		if (reverser_0 == 0) {
			me["engine0rev"].hide();
		} else {
			me["engine0rev"].show();
			if (reverser_0 < 1) {
				me["engine0rev"].setColor(1,0.749,0);
			} else {
				me["engine0rev"].setColor(0,1,0);
			}
		}
		if (reverser_1 == 0) {
			me["engine1rev"].hide();
		} else {
			me["engine1rev"].show();
			if (reverser_1 < 1) {
				me["engine1rev"].setColor(1,0.749,0);
			} else {
				me["engine1rev"].setColor(0,1,0);
			}
		}

	},
};

setlistener("sim/signals/fdm-initialized", func() {
	upperEICAS_display = canvas.new({
		"name": "upperEICAS",
		"size": [1024, 1024],
		"view": [1024, 1024],
		"mipmapping": 1
	});
	upperEICAS_display.addPlacement({"node": "upperEICASScreen"});
	var group = upperEICAS_display.createGroup();
	upperEICAS_canvas = canvas_upperEICAS.new(group);
        upperEICAS_canvas.newMFD();
 	#upperEICAS_canvas.update();
}, 0, 0);

#setlistener("sim/signals/reinit", func upperEICAS_display.del());

var showupperEICAS = func() {
	var dlg = canvas.Window.new([512, 512], "dialog").set("resize", 1);
	dlg.setCanvas(upperEICAS_display);
}
