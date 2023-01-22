import("stdfaust.lib");

declare author "Evermind";
declare license "BSD 3-clause";

//Parameters
feedback_amount = vslider("t:6171 Reverb/h:Main/[0]Feedback %", 70, 0, 90, 0.1) / 100;
crosstalk = vslider("t:6171 Reverb/h:Main/[1]Crosstalk", 30, 0, 100, 1) / 100;
wet_level = vslider("t:6171 Reverb/h:Main/[2]Wet %", 25, 0, 100, 1) / 100;
outgain = vslider("t:6171 Reverb/h:Main/[3]Out Gain", 0, -24, 24, .1) : ba.db2linear : si.smoo;

ldelay1 = hslider("t:6171 Reverb/v:[3]Timings/h:Left Channel/Delay 1[unit:ms][style:knob]", 100, 1, 400, 0.1) / 1000 : ba.sec2samp;
ldelay2 = hslider("t:6171 Reverb/v:[3]Timings/h:Left Channel/Delay 2[unit:ms][style:knob]", 68, 1, 400, 0.1) / 1000 : ba.sec2samp;
ldelay3 = hslider("t:6171 Reverb/v:[3]Timings/h:Left Channel/Delay 3[unit:ms][style:knob]", 19.7, 1, 400, 0.1) / 1000 : ba.sec2samp;
ldelay4 = hslider("t:6171 Reverb/v:[3]Timings/h:Left Channel/Delay 4[unit:ms][style:knob]", 5.9, 1, 400, 0.1) / 1000 : ba.sec2samp;
rdelay1 = hslider("t:6171 Reverb/v:[3]Timings/h:Right Channel/Delay 1[unit:ms][style:knob]", 112, 1, 400, 0.1) / 1000 : ba.sec2samp;
rdelay2 = hslider("t:6171 Reverb/v:[3]Timings/h:Right Channel/Delay 2[unit:ms][style:knob]", 53, 1, 400, 0.1) / 1000 : ba.sec2samp;
rdelay3 = hslider("t:6171 Reverb/v:[3]Timings/h:Right Channel/Delay 3[unit:ms][style:knob]", 21.7, 1, 400, 0.1) / 1000 : ba.sec2samp;
rdelay4 = hslider("t:6171 Reverb/v:[3]Timings/h:Right Channel/Delay 4[unit:ms][style:knob]", 7, 1, 400, 0.1) / 1000 : ba.sec2samp;


//Functions
allpass(dt,gain) = (+ <: de.delay(ma.SR/2,dt-1),*(gain)) ~ *(-gain) : mem,_ : +;
schroeder_verb(dt1, dt2, dt3, gain) = allpass(dt1,gain) : allpass(dt2, gain) : allpass(dt3, gain);
schroeder_delays(dt1, dt2, dt3, dt4, dt5, dt6, lgain, rgain) = schroeder_verb(dt1, dt2, dt3, lgain),
                                   schroeder_verb(dt4, dt5, dt6, rgain);
gerzon_delays(dt1, dt2) = (allpass(dt1,1),
                           allpass(dt2,1));
routing(a,b,c,d) = (a+c), (b+d);
mix_channels(ct) = _,_ <: *(1-ct)+*(ct), *(ct)+*(1-ct);

reverb = schroeder_delays(ldelay1, ldelay2, ldelay3, rdelay1, rdelay2, rdelay3, feedback_amount, feedback_amount) :
        (routing : gerzon_delays(ldelay4, rdelay4) : mix_channels(crosstalk)) ~ (*(feedback_amount), *(feedback_amount));

process = _,_ <: (_,_), reverb: ro.interleave(2,2) : it.interpolate_linear(wet_level), it.interpolate_linear(wet_level) : * (outgain), *(outgain);
