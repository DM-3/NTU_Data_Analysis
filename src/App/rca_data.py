# ==================================================
# RCA KNOWLEDGE BASE (WM-811K)
# ==================================================
RCA_DATA = {

    # ==================================================
    # CENTER
    # ==================================================
    "Center": {
        "summary": "Failure in thin film deposition causing center-localized defects",
        "severity": "Medium",
        "process": "Thin Film Deposition",

        "root_cause": [
            "CVD gas flow stagnation at wafer center",
            "Non-uniform PVD flux distribution",
            "Incomplete ALD saturation at center",
            "Photoresist pooling during spin coating",
        ],

        "tools": [
            "CVD chamber",
            "PVD sputtering system",
            "ALD reactor",
            "Spin coater",
        ],

        "actions": [
            "Measure radial film thickness (ellipsometry)",
            "Inspect CVD showerhead for clogging",
            "Optimize PVD target power distribution",
            "Increase ALD pulse duration",
            "Verify spin coating speed and ramp profile",
        ],
    },

    # ==================================================
    # DONUT
    # ==================================================
    "Donut": {
        "summary": "Mid-radius ring due to photoresist redeposition or CMP non-uniformity",
        "severity": "Medium",
        "process": "Photolithography / CMP",

        "root_cause": [
            "Developer recirculation causing resist redeposition",
            "Insufficient rinse removing dissolved resist",
            "EBR overspray depositing resist inward",
            "CMP slurry starvation at mid-radius",
        ],

        "tools": [
            "Develop track",
            "Rinse station (DI water)",
            "EBR nozzle",
            "CMP tool",
        ],

        "actions": [
            "Optimize develop spin speed",
            "Increase rinse duration and coverage",
            "Adjust EBR nozzle angle and flow",
            "Improve CMP slurry distribution",
            "Perform SEM cross-section at defect ring",
        ],
    },

    # ==================================================
    # EDGE-LOC
    # ==================================================
    "Edge-Loc": {
        "summary": "Localized edge defect due to asymmetric process conditions",
        "severity": "Medium-High",
        "process": "Diffusion / Etch",

        "root_cause": [
            "Uneven furnace heating (one-sided)",
            "Partial gas port blockage",
            "Focus ring damage on one sector",
            "Wafer chuck particle causing tilt",
        ],

        "tools": [
            "Diffusion furnace",
            "Plasma etch chamber",
            "Focus ring",
            "Wafer chuck",
        ],

        "actions": [
            "Map temperature distribution in furnace",
            "Check gas flow balance per port",
            "Inspect focus ring for damage",
            "Clean wafer chuck and verify flatness",
            "Match defect angle with tool geometry",
        ],
    },

    # ==================================================
    # EDGE-RING
    # ==================================================
    "Edge-Ring": {
        "summary": "Full edge ring caused by radially symmetric etch/deposition issues",
        "severity": "High",
        "process": "Etching / Deposition",

        "root_cause": [
            "Plasma confinement ring degradation",
            "CVD edge cooling and gas imbalance",
            "PVD target erosion (racetrack)",
            "Furnace radial temperature gradient",
            "ALD edge temperature mismatch",
        ],

        "tools": [
            "Plasma etch chamber",
            "CVD system",
            "PVD system",
            "Diffusion furnace",
            "ALD reactor",
        ],

        "actions": [
            "Inspect and replace confinement ring",
            "Check edge temperature profile",
            "Monitor PVD target wear level",
            "Run radial etch rate test wafer",
            "Adjust heater zones for edge compensation",
        ],
    },

    # ==================================================
    # LOC
    # ==================================================
    "Loc": {
        "summary": "Fixed-location defect caused by vibration or repeated contamination",
        "severity": "Medium",
        "process": "Equipment / Lithography",

        "root_cause": [
            "Tool vibration causing localized disturbance",
            "Chamber wall particle flaking",
            "Reticle contamination",
            "Robot end-effector contamination",
        ],

        "tools": [
            "Process tool (vibration source)",
            "Chamber walls",
            "Lithography reticle",
            "Wafer handling robot",
        ],

        "actions": [
            "Perform vibration analysis",
            "Clean chamber and monitor particles",
            "Inspect reticle under microscope",
            "Track defect coordinates across wafers",
            "Map defect location to tool geometry",
        ],
    },

    # ==================================================
    # NEAR-FULL
    # ==================================================
    "Near-full": {
        "summary": "Catastrophic process failure affecting entire wafer",
        "severity": "Critical",
        "process": "Multiple / Global",

        "root_cause": [
            "Wrong chemical bath or concentration",
            "CVD/ALD heater or gas failure",
            "Vacuum leak during etch",
            "Furnace temperature excursion",
            "Epitaxy autodoping failure",
        ],

        "tools": [
            "Wet bench",
            "CVD/ALD chamber",
            "Plasma etch system",
            "Diffusion furnace",
            "Epitaxy reactor",
        ],

        "actions": [
            "⚠ Quarantine affected lot immediately",
            "Audit full process history (SPC)",
            "Check chemical concentrations",
            "Run full tool diagnostics",
            "Perform failure analysis (SEM, EDX, SIMS)",
        ],
    },

    # ==================================================
    # SCRATCH
    # ==================================================
    "Scratch": {
        "summary": "Mechanical damage from handling or CMP process",
        "severity": "High",
        "process": "CMP / Handling",

        "root_cause": [
            "Robot misalignment dragging wafer",
            "CMP slurry particle agglomeration",
            "Damaged CMP polishing pad",
            "Cassette slot burrs",
            "Manual handling errors",
        ],

        "tools": [
            "Wafer handling robot",
            "CMP tool",
            "Cassette/FOUP",
            "Manual handling tools",
        ],

        "actions": [
            "Inspect scratch direction to identify source",
            "Calibrate robot alignment",
            "Check slurry particle size distribution",
            "Inspect CMP pad condition",
            "Replace damaged cassettes",
        ],
    },

    # ==================================================
    # RANDOM
    # ==================================================
    "Random": {
        "summary": "Scattered defects caused by contamination or process instability",
        "severity": "Variable",
        "process": "Environment / Multiple",

        "root_cause": [
            "Airborne particle contamination",
            "Wet chemistry contamination",
            "FOUP seal degradation",
            "Process parameter drift",
        ],

        "tools": [
            "FOUP / SMIF",
            "Wet bench",
            "Cleanroom environment",
            "Process tools",
        ],

        "actions": [
            "Check particle levels in FOUP",
            "Audit chemical purity",
            "Run SPC trend analysis",
            "Minimize open-air exposure",
            "Monitor defect density trends",
        ],
    },
}