MARGO
=====

## Description

The Massively Automated Real-time GUI for Object-tracking (MARGO) is a MATLAB based tracking platform designed with an emphasis on high-throughput tracking of large groups of animals and tracking applications requiring closed-loop hardware control. See below for examples of MARGO applications.

<figure align="center">
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/fly_960_gif.gif" width="95%"/>
    <figcaption>
        Sample video clip from an experiment featuring continuous high-throughput tracking of 960 fruit tracked at 8Hz for 6 days
    </figcaption>
</figure>
<br/>

## Installation

### Prerequisites

**MATLAB**

For best results, use MARGO with **MATLAB 2016b** or newer. MARGO has generally been designed to be backwards compatible with older versions of MATLAB. In addition to the base installation of MATLAB, MARGO uses the *image acquisition* and *image processing* toolboxes.

**Psychtoolbox (optional)**

MARGO requires on [Psychtoolbox 3](http://psychtoolbox.org/) for support of external displays.

### MARGO installation

The MARGO repository can be cloned via the github UI by downloading and extracting a zip file (*Clone or Download* > *Download ZIP*) or via the git command line API with the following command:

```
git clone https://github.com/de-Bivort-Lab/margo.git
```

After cloning the repository, add the MARGO directory to MATLAB's path by navigating to the margo directory and running:

```
add(genpath(margo));
```

Alternatively, permanently add MARGO and all sub folders to the MATLAB path by adding by running:

```
pathtool
```

Once the margo directory is added to the MATLAB path, launch the GUI from the command line:

```matlab
margo
```

## Quickstart Guide

We recommend that new users read about MARGO's [experimental workflow](##experimental-workflow) and follow the sample [tracking tutorial](https://github.com/de-Bivort-Lab/margo/wiki/Tracking-Tutorial) included in the documentation for more complete instructions on getting started in MARGO.

<figure style="text-align: center">
    <img src="../../images/quickstart/quick_start_guide.png" style="width: 95%"/>
    <figcaption class="center_cap" style="text-align: center">
    </figcaption>
</figure>

## Documentation

Complete documentation of MARGO including tutorial examples, descriptions of parameters, data outputs, and hardware configurations can be found on the [MARGO wiki](https://github.com/de-Bivort-Lab/margo/wiki).

## Sample Applications

### Closed-loop control of stimuli

<figure align="center">
    <img src="led_ymaze_gif.gif" width="375"/> &nbsp; &nbsp;
    <img src="led_ymaze_gif.gif" width="375"/>
    <figcaption align=left>
        Closed-loop applications: (left) triggering LEDs based on position of flies in a Y-shaped mazes, (right) targeting optomotor stimuli to individual flies in circular arenas
    </figcaption>
</figure>

<br/>

### Multi-species tracking

The Massively Automated Real-time GUI for Object-tracking (MARGO) is a MATLAB based tracking platform designed with an emphasis on high-throughput tracking of large groups of animals and tracking applications requiring closed-loop stimulus control.

<br/>

<figure align="center">
    <img src="bee_gif.gif" width="360"/> &nbsp; &nbsp;
    <img src="zebrafish_gif.gif" width="384"/>
    <figcaption>
        Sample tracking of bumblebees (left) in a nestbox and larval zebrafish (right) in a multi-well culture plate
    </figcaption>
</figure>


<figure align="center">
    <img src="larval_gif.gif" width="373"/> &nbsp; &nbsp;
    <img src="wormotel_gif.gif" width="370"/>
    <figcaption>
        Sample tracking of fruit fly larvae (left) in a chemotactic gradient and nematodes (right) in response to an optogenetic stimulus
    </figcaption>
</figure>


<br/>

## License

MIT License. See [LICENSE](https://github.com/de-Bivort-Lab/margo/blob/master/LICENSE.md) for details.

