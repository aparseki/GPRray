# GPRray
Multi-offset GPR raytracing script in MATLAB

1.	Purpose

This function calculates the travel time of one or more refracted and reflected rays along paths determined by a set number of layers with set velocities at predetermined source-receiver offsets.  Each reflection point is defined as being the mid-point between the source and receiver; refraction is accounted for at layers with contrasting velocity.

2.	Method

Snell’s law is implemented at each interface to correctly bend each ray. Since the angle of incidence on layer 1 is unknown, optimization is used to find the shortest path between each source-receiver pair given the subsurface geometry and velocity structure. All functions used in this script are built into basic MATLAB so no external toolboxes are required.

Please see the following reference for detailed explanation of this approach:

Parsekian, A.D. (2018) Inverse Methods To Improve Accuracy of Water Content Estimates from Multi-offset GPR. Journal of Environmental and Engineering Geophysics (2018) 23 (3): 349-361.https://doi.org/10.2113/JEEG23.3.349

3.	Instructions (see instruction video here: https://youtu.be/uRJUrGznOt0)

In MATLAB, navigate to the directory where this function (GPRray.m) is saved.  Either in a script or in the command window, define the three required vectors for x-position of each receiver (x), the velocity of each layer (v) and the thickness of each layer (z).  The source is fixed at (0,0).  Vectors v and z must be of the same length. For example:

x = 1:.1:5;
v = [0.12 0.08 0.10];
z = [1.0 1.5 1.5];

Execute the function with an output variable defined (in this case, TT, to represent travel time) and the fourth input parameter being either a 1 (yes plot) or 0 (no plot). The fifth input is a noise scaling factor, however noise is only added to the output data TT, not the figure. 

TT = GPRray(x,v,z,1,0.1);

Selecting the plotting ‘yes’ option with a number 1 will cause two figures to be generated on the screen – one showing the geometric raypaths depth versus offset, and a second showing the travel time-offset curves for each layer.

 
4.	Speed

The forward model is solved at a speed proportional primarily to the number of layers and the number of receivers, but velocity structure is a second-order effect.

5. GPRrayInv

Uses the GPRray forward model to invert multoffset data for velocity structure and depth. Requires input of DATA in the same format as the output of GPRray with ploton set to 1. The starting model "st" is currently hard coded to be uniform 0.1 m/ns and 1m thickness for all layers because sometimes using Dix to estimate a starting model causes non-physical velocities or complex numbers. The inversion criteria "crit" works best set to 1e-3 - this applies to the step size and convergence criteria. Seems to work best with smaller stepsize.

6. Pick Files

Currently can import pick files from ReflexW into the "DATA" format needed by GPRrayInv. FormatGroup should be set to ASCII-columns, "export several pick..." should NOT be checked, ColumnsGroupBox: "trace number," "pick codes" should be the ONLY boxes checked. Must also pick airwave (pick code 0) and ground wave (pick code 1), though they are not used right now.  If no groundwave is visible, then just pick anything - there need to be some values in this catagory. The resulting PCK file should have exactly seven (7) columns, otherwise this will not work. In general, it is much better to pick more traces if possible, though the run time increases with number of picks and layers.

7. Uncertainty

Currently only bootstrapping uncertainty is implimented.  This is a data-driven approach to estimating uncertainty on all inverted parameters, however it is slow unfortunately.  More about this approach can be found in Parsekian and Grombacher 2015 (Journal of Applied Geophysics) [note: this article is for NMR, but the principles are the same].

Parsekian, A. D., & Grombacher, D. (2015). Uncertainty estimates for surface nuclear magnetic resonance water content and relaxation time profiles from bootstrap statistics. Journal of Applied Geophysics, 119, 61-70.
