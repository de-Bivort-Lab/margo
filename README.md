MARGO
=====

## Description

The Massively Automated Real-time GUI for Object-tracking (MARGO) is a MATLAB based tracking platform designed with an emphasis on high-throughput tracking of large groups of animals and tracking applications requiring closed-loop hardware control. See below for examples of MARGO applications.

<figure align="center">
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/fly_960_gif.gif" width="95%"/>
    <figcaption>
        Sample video clip from an experiment featuring continuous high-throughput tracking of 960 fruit flies tracked at 8Hz for 6 days
    </figcaption>
</figure>
<br/>

## Installation

### Prerequisites

**MATLAB**

For best results, use MARGO with **MATLAB 2016b** or newer. MARGO has generally been designed to be backwards compatible with older versions of MATLAB. In addition to the base installation of MATLAB, MARGO requires the following toolboxes:
- image acquisition toolbox
- image processing toolbox
- computer vision system toolbox
- instrument control toolbox
- statistics and machine learning toolbox

**Psychtoolbox (optional)**

MARGO requires on [Psychtoolbox 3](http://psychtoolbox.org/) for support of external displays.

### MARGO installation

<p text-align="left">
1. The MARGO repository can be cloned via the github UI by downloading and extracting a zip file of the repository (<i>Clone or Download</i> > <i>Download ZIP</i>) &nbsp; <ins>OR</ins>&nbsp; clone via the git command line API with the following command:
</p>

```
git clone https://github.com/de-Bivort-Lab/margo.git
```

<p text-align="left">
2. After cloning the repository, add the MARGO directory to MATLAB's path by navigating to the margo directory and running:
</p>

```
addpath(genpath(pwd));
```

<ins>OR</ins>

Alternatively, permanently add MARGO and all sub folders to the MATLAB path by adding by running:

```
    pathtool
```

<p text-align="left">
3. Once the margo directory is added to the MATLAB path, launch the GUI from the command line:
</p>

```matlab
margo
```

## Getting Started

We recommend that new users read the [overview](https://github.com/de-Bivort-Lab/margo/wiki/Introduction#overview) of MARGO's functionality and use the sample video included in this repository to follow the [tracking tutorial](https://github.com/de-Bivort-Lab/margo/wiki/Tracking-Tutorial) included in the documentation for more complete instructions on getting started in MARGO.

## Documentation

Complete documentation of MARGO including tutorial examples, descriptions of parameters, data outputs, and hardware configurations can be found on the [MARGO wiki](https://github.com/de-Bivort-Lab/margo/wiki).

## Sample Applications

### Closed-loop control of stimuli

<p align="center">
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/led_ymaze_gif.gif" width="374"/> &nbsp; &nbsp;
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/opto_gif_2.gif" width="374"/>
    <figcaption align=left>
        Closed-loop applications: (left) triggering LEDs based on position of flies in a Y-shaped mazes, (right) targeting optomotor stimuli to individual flies in circular arenas
    </figcaption>
</p>

<br/>

### Multi-species tracking

The Massively Automated Real-time GUI for Object-tracking (MARGO) is a MATLAB based tracking platform designed with an emphasis on high-throughput tracking of large groups of animals and tracking applications requiring closed-loop stimulus control.

<br/>

<p align="center">
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/bee_gif.gif" width="360"/> &nbsp; &nbsp;
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/zebrafish_gif.gif" width="384"/>
</p>
<p align="center">
    Sample tracking of bumblebees (left) in a nestbox and larval zebrafish (right) in a multi-well culture plate
</p>


<p align="center">
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/larval_gif.gif" width="373"/> &nbsp; &nbsp;
    <img src="https://github.com/de-Bivort-Lab/margo/wiki/images/margo_readme/wormotel_gif.gif" width="370"/>
</p>
<p align="left">
Tracking of fruit fly larvae (left) in a chemotactic gradient and nematodes (right) in response to an optogenetic stimulus in the <a href="https://elifesciences.org/articles/26652">wormotel</a> high-throughput platform
</p>

<br/>

## Reporting issues

MARGO is still a work in progress. Please [report](https://github.com/de-Bivort-Lab/margo/issues) any errors to this repository. To help solve issues quickly, please provide a detailed description of the error, the MATLAB error message, and the MARGO error log file (if possible).

## Contributors

- [Zach Werkhoven](https://github.com/winsl0w) primarily developed and maintains MARGO.
- [Chuan Qin](https://github.com/cqin19) contributed to the development of MARGO's multitracker algorithm.
- [Christian Rohrsen](https://github.com/chiser) contributed to the development of MARGO's camera/display co-registration system.

## Acknowledgements

Support for external display detection and visual stimulus crafting and display is dependent on the [Psychtoolbox](http://psychtoolbox.org/overview.html), originally developed by Mario Kleiner. MARGO's random display registration uses Andriy Myronenko's [Coherent Point Drift](https://sites.google.com/site/myronenko/research/cpd) algorithm and mex implementation. Multispecies tracking example videos provided by: James Crall (bumblebees), Jess Kanwal (fly larvae), and Matt Churgin (C. Elegans). 

## License

MIT License. See [LICENSE](https://github.com/de-Bivort-Lab/margo/blob/master/LICENSE.md) for details.

