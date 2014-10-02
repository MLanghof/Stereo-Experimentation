Stereo-Experimentation
======================

This project is an attempt to create a real time stable stereo matching algorithm that could work with two head-mounted cameras.

The prospect of being able to use virtual/augmented reality in every day life got me pretty hooked (quite) a while back when I learned about the Epson Moverio.
Sure, Google Glass was a thing back then, but having a display somewhere outside your normal field of view is very different from having 3D scenery added to your surroundings.

Not only would such a stereo vision system be able to recognize, understand and "interact" with the environment you see (random example: Display translated text on street signs in a foreign country), it would also enable you to use gesture controls!
As you can probably imagine, the possible applications for a wearable system (yeah, more glasses...) using this would hardly be limited.
The "wearable" aspect together with the need for two cameras already means power usage and battery life will be a great concern. As such, sheer processing power is out of the question to achieve real time applicability.

Currently I'm still building the necessary "infrastructure" for realizing different ideas. I chose Processing as language since it's naturally very close to image processing and provides a lot of convenience in many different ways. It will not be the language of choice for a real-time application, but I currently don't even own a Moverio (or Google Glass). Neither of them have stereoscopic cameras anyway.
Quite a bit of the calculation currently also happens in the realms of the GPU. For example, the rectangulation process inherent to virtually any stereo vision algorithm can be performed in a single rendering of the image!
