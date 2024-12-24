Wrote a blog post on this: https://ckalitin.github.io/space/2024/07/24/kos-booster-landing.html

Put the this repository in the Ships/Scripts folder in the KSP directory and then call it with "switch to 0." "cd kos." "run land."

Notes:  
Final descent should be a single function, add cancelling out horizontal velocity into it.  
Currently, cancelling horizontal velocity is only done in the final flight phase, <50m above the surface.  
Bad solution and this requires the offset in target pos, just add horizontal velocity cancelling to a general descent function, like those F9 videos.
Entry burn is an example of a stupid solution, it should be fully aero. Stress tested at ~1.4 km/s entry velocity at 10 degree latlng offset.
+  The refactor didn't work because it was too slow, use unlock? No, use when instead of until. Neither of these worked, updating every frame is very computationally intensive. Why?

On Sep 8/9 2024 the landing burn function was changed to account for the landing burn itself changing the original impact pos estimate, the estimate is slightly more accurate now. This is in the last paragraph of the "No Unifed Solution To Cancel Horizontal Velocity and Minimize Landing Error" section of the blog post, I laid out the ideas of what I did. This solves most of the notes, except integrating horizontal velocity cancellation and landing burn into a single function.

I'm on the UBC Solar design team now and see how "professionals" do things, more notes are good.

It might be possible to do this without kOS bullshit language, instead the less bullshit Python:
https://www.youtube.com/watch?v=MQjr3zI_0B0

kRPC: https://krpc.github.io/krpc/
(from the I2Rocketguy stream)
