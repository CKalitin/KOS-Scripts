Wrote a blog post on this: https://ckalitin.github.io/space/2024/07/24/kos-booster-landing.html

Put the this repository in the Ships/Scripts folder in the KSP directory.

Notes:  
Final descent should be a single function, add cancelling out horizontal velocity into it.  
Currently, cancelling horizontal velocity is only done in the final flight phase, <50m above the surface.  
Bad solution and this requires the offset in target pos, just add horizontal velocity cancelling to a general descent function, like those F9 videos.  
Entry burn is an example of a stupid solution, it should be fully aero. Stress tested at ~1.4 km/s entry velocity at 10 degree latlng offset.

The refactor didn't work because it was too slow, use unlock? No, use when instead of until.
