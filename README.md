# sNMAC-Initial

This MATLAB code supported, "A Quantitatively Derived NMAC Analog for Smaller Unmanned Aircraft Systems Based on Unmitigated Collision Risk." It provides an initial quantitative assessment of sNMAC candidates. A final and adopted sNMAC definition should be informed by stakeholder needs, such as those of the FAA and standards developing organizations.

- [sNMAC-Initial](#snmac-initial)
  - [Nomenclature](#nomenclature)
  - [Metric to Evaluate Collision Avoidance Systems](#metric-to-evaluate-collision-avoidance-systems)
    - [NMAC](#nmac)
    - [sNMAC](#snmac)
  - [Objective](#objective)
  - [Assumptions](#assumptions)
  - [Method](#method)
  - [Run Order](#run-order)
  - [Citation](#citation)
  - [Distribution Statement](#distribution-statement)

## Nomenclature

Acronym | Phrase
:--- | :---
AGL | above ground level
CPA | closest point of approach
DAA | detect and avoid
MAC | [Mid Air Collision](https://en.wikipedia.org/wiki/Mid-air_collision)
HMD | horizontal miss distance
NMAC | Near Mid Air Collision
sNMAC | Smaller Near Mid Air Collision
TCAS | [traffic collision avoidance system](https://en.wikipedia.org/wiki/Traffic_collision_avoidance_system)
UAS  | [unmanned aerial system](https://en.wikipedia.org/wiki/Unmanned_aerial_vehicle)
VMD | vertical miss distance

## Metric to Evaluate Collision Avoidance Systems

### NMAC

- Aircraft must operate as to not create a MAC hazard due to the loss of life and property
- Collision avoidance systems are mandated to minimize the MAC risk between aircraft
  - Systems defined by sets of performance requirements
  - Separation criteria dependent upon the types of encountering aircraft
- Fast-time modeling and simulation routinely used to evaluate these systems
- MAC statistics are difficult to estimate, so NMACs are used as a preferred metric
  - Defined as a loss of separation 500 feet horizontally and 100 feet vertically
  - Acts as a "measuring stick" for assessing the goodness of a system
  - Originally quantitatively defined to support safety evaluations of TCAS in the 1980s
- NMAC was defined using assumptions for encounters with only manned aircraft, these assumptions are not representative of UAS-only encounters
  - NMAC is a potential but not a reasonable metric to evaluate smaller UAS safety

### sNMAC

- The size of a given UAS is generally significantly smaller than a manned aircraft, with many low altitude smaller UASs having a wingspan of 15 feet or less
- The altitudes, closing speeds, and dynamics of UAS-only encounters are significantly different than encounters with manned aircraft
  - Expected to occur at lower altitudes of 1200-500 feet AGL or less
  - Different aircraft flight performance and dynamics

## Objective

The objective of this work is to propose a sNMAC criteria that can be used to evaluate safety systems that mitigate the likelihood of a MAC for encounters between smaller UASs.

- Quantitatively define what constitutes a close encounter between smaller UASs in simulation
- Support safety modeling and simulation efforts, specifically [RTCA SC-147](https://www.rtca.org/content/sc-147)
- Exclude incident reporting criteria from initial scope
- Functionally analogous to NMAC’s role in evaluating safety systems for manned aircraft

## Assumptions

- Applicable to all smaller UAS with a wingspan of 25 feet or less (no MGTOW limit)
- No consideration for or enforcing a 5:1 horizontal to vertical ratio like NMAC
  - No technical justification for a 5:1 ratio based on NMAC literature review
- Uniform and consistent across all use cases
  - Should not vary based on altitude, aircraft performance, location, operating limitations, time, or wake turbulence, etc.
  - No consideration for small UAS operating limits defined by [14 CFR § 107.51](https://ecfr.gov/cgi-bin/text-idx?SID=cbce422a6ed5e050591cf99f7a1a62e0&mc=true&node=se14.2.107_151&rgn=div8)
  - NMAC is also a static volume, it does not change depending upon performance or operations
- Aligned with aviation norms, dimensions should be a multiple of 5, such as 25 feet
- Position error initially not considered; final criteria will include more considerations
  - No upfront consideration for the 20 feet altitude accuracy in the Remote ID NPRM
  - Violation reporting and flight testing implications could also be considered
  - Quantization only considered for rounding purposes

## Method

This code supports the following process:

1. Select independent minimum and maximum limits for wingspan and height
2. Select independent distribution types for wingspan and height
3. Generate a set of horizontal and vertical miss distances
4. Drawing from wingspan and height distributions (#2) assess in a first-order physics simulation the likelihood of MAC given horizontal and vertical miss distances (#3)
5. Visualize likelihood of a MAC given #4
6. Downselect sNMAC candidates that support desired P(MAC|sNMAC) threshold

## Run Order

This code was developed and tested using MATLAB 9.7.0.1190202 (R2019b) and 9.4.0.949201 (R2018a).

The main script is [`RUN_sNMACDefinition`](RUN_sNMACDefinition.m). The calculation parameters are set using [`setParameters`](setParameters.m) and has the following built-in use cases:

simCase | Description | Width Distribution | Height Distribution
 :---: | :--- | :--- | :---
1 | Manned aircraft | Uniform | Uniform
2 | Smaller UAS | Uniform | Uniform
3 | Smaller UAS | "worst case" / largest indicator function | Uniform
4 | Smaller UAS | Left skew | Uniform
5 | Smaller UAS | Rigth skew | Uniform
6 | Smaller UAS | Normal | Uniform

[`RUN_observability`](RUN_observability.m) should be used to assess the observability of a sNMAC candidate given different position error and vertical miss distances.

## Citation

Please use this reference when citing the software or the publication the software supports:

<details> <summary> A. Weinert, L. Alvarez, M. Owen and B. Zintak, “A Quantitatively Derived NMAC Analog for Smaller Unmanned Aircraft Systems Based on Unmitigated Collision Risk,” 2020.</summary>
<p>

```tex
@inproceedings{weinertsNMAC2020,
	title = {A Quantitatively Derived NMAC Analog for Smaller Unmanned Aircraft Systems Based on Unmitigated Collision Risk,
	language = {en},
	author = {Weinert, Andrew and Alvarez, Luis and Owen, Michael and Zintak, Benjamin},
	year = {2020},
}
```
</p>
</details>

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2020 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
