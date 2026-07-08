"""
Mock dataset definitions for CivicTwin AI.

Isolated from `seed_database.py` execution logic so the dataset itself can be
reviewed, extended, or swapped independently of the seeding mechanism.

All values conform exactly to the field specs in EDD V2, Document 02.
"""

from typing import Any

# ---------------------------------------------------------------------------
# system_config/sys_01
# ---------------------------------------------------------------------------
SYSTEM_CONFIG: dict[str, Any] = {
    "id": "sys_01",
    "bhashini_endpoint": "https://mock.bhashini.gov.in/api/v1/translate",
    "gemini_active_model": "gemini-2.5-pro",
    "impact_weights": {
        "population": 0.30,
        "severity": 0.25,
        "efficiency": 0.20,
        "infrastructure": 0.15,
        "signals": 0.10,
    },
}

# ---------------------------------------------------------------------------
# constituencies/const_mumbai_north
# ---------------------------------------------------------------------------
CONSTITUENCY: dict[str, Any] = {
    "id": "const_mumbai_north",
    "name": "Mumbai North",
    "state": "Maharashtra",
    "total_budget_allocated": 50_000_000,  # ₹5 Crore MPLADS pool
    "budget_utilized": 24_600_000,        # ₹24.6L utilized baseline (from user request)
    "center": {"latitude": 19.215, "longitude": 72.845},
}

# ---------------------------------------------------------------------------
# constituencies/const_mumbai_north/wards
# ---------------------------------------------------------------------------
WARDS: list[dict[str, Any]] = [
    {
        "id": "ward_14",
        "ward_number": "14",
        "name": "Malad East",
        "population": 62_400,
        "critical_infrastructure_count": 3,
        "polygon_coordinates": [
            {"latitude": 19.1854, "longitude": 72.8424},
            {"latitude": 19.1900, "longitude": 72.8520},
            {"latitude": 19.1820, "longitude": 72.8600},
            {"latitude": 19.1760, "longitude": 72.8510},
        ],
    },
    {
        "id": "ward_17",
        "ward_number": "17",
        "name": "Kandivali West",
        "population": 74_100,
        "critical_infrastructure_count": 5,
        "polygon_coordinates": [
            {"latitude": 19.2054, "longitude": 72.8324},
            {"latitude": 19.2100, "longitude": 72.8420},
            {"latitude": 19.2020, "longitude": 72.8500},
            {"latitude": 19.1960, "longitude": 72.8410},
        ],
    },
    {
        "id": "ward_09",
        "ward_number": "09",
        "name": "Borivali South",
        "population": 58_900,
        "critical_infrastructure_count": 4,
        "polygon_coordinates": [
            {"latitude": 19.2254, "longitude": 72.8524},
            {"latitude": 19.2300, "longitude": 72.8620},
            {"latitude": 19.2220, "longitude": 72.8700},
            {"latitude": 19.2160, "longitude": 72.8610},
        ],
    },
    {
        "id": "ward_22",
        "ward_number": "22",
        "name": "Dahisar West",
        "population": 45_200,
        "critical_infrastructure_count": 2,
        "polygon_coordinates": [
            {"latitude": 19.2454, "longitude": 72.8624},
            {"latitude": 19.2500, "longitude": 72.8720},
            {"latitude": 19.2420, "longitude": 72.8800},
            {"latitude": 19.2360, "longitude": 72.8710},
        ],
    },
    {
        "id": "ward_05",
        "ward_number": "05",
        "name": "Goregaon East",
        "population": 51_600,
        "critical_infrastructure_count": 6,
        "polygon_coordinates": [
            {"latitude": 19.1654, "longitude": 72.8524},
            {"latitude": 19.1700, "longitude": 72.8620},
            {"latitude": 19.1620, "longitude": 72.8700},
            {"latitude": 19.1560, "longitude": 72.8610},
        ],
    },
]

# ---------------------------------------------------------------------------
# constituencies/const_mumbai_north/signals (Exactly 32 Feeds)
# ---------------------------------------------------------------------------
SIGNALS: list[dict[str, Any]] = [
    # WARD 14 (Malad East)
    {
        "id": "sig_1001",
        "ward_id": "ward_14",
        "category": "Water Leakage",
        "severity": 6,
        "coords": {"latitude": 19.1830, "longitude": 72.8480},
        "description": "Substantial water pipe rupture near Malad East Subway corridor.",
        "status": "Open",
    },
    {
        "id": "sig_1002",
        "ward_id": "ward_14",
        "category": "Road Damage",
        "severity": 9,  # CRITICAL 1
        "coords": {"latitude": 19.1810, "longitude": 72.8510},
        "description": "Severe structural asphalt collapse at the Western Express Highway service exit.",
        "status": "Open",
    },
    {
        "id": "sig_1003",
        "ward_id": "ward_14",
        "category": "Garbage Overflow",
        "severity": 5,
        "coords": {"latitude": 19.1795, "longitude": 72.8465},
        "description": "Garbage clearing delay at Kurar Village municipal dumping bin.",
        "status": "Open",
    },
    {
        "id": "sig_1004",
        "ward_id": "ward_14",
        "category": "Street Light Failure",
        "severity": 3,
        "coords": {"latitude": 19.1860, "longitude": 72.8490},
        "description": "Broken street lights fixed near Appa Pada slums.",
        "status": "Closed",
    },
    {
        "id": "sig_1005",
        "ward_id": "ward_14",
        "category": "Illegal Dumping",
        "severity": 7,
        "coords": {"latitude": 19.1870, "longitude": 72.8530},
        "description": "Construction debris illegally dumped along Sanjay Gandhi National Park boundary.",
        "status": "Open",
    },
    {
        "id": "sig_1006",
        "ward_id": "ward_14",
        "category": "Drainage Blockage",
        "severity": 8,
        "coords": {"latitude": 19.1800, "longitude": 72.8550},
        "description": "Silt build-up blocking main storm water channel behind Malad East Station.",
        "status": "Open",
    },
    {
        "id": "sig_1007",
        "ward_id": "ward_14",
        "category": "Traffic Congestion",
        "severity": 4,
        "coords": {"latitude": 19.1825, "longitude": 72.8445},
        "description": "Traffic signal cycle updated at WEH Malad intersection.",
        "status": "Closed",
    },

    # WARD 17 (Kandivali West)
    {
        "id": "sig_2001",
        "ward_id": "ward_17",
        "category": "Road Damage",
        "severity": 8,
        "coords": {"latitude": 19.2040, "longitude": 72.8460},
        "description": "Massive potholes covering MG Road, Kandivali West, obstructing vehicular flow.",
        "status": "Open",
    },
    {
        "id": "sig_2002",
        "ward_id": "ward_17",
        "category": "Water Leakage",
        "severity": 5,
        "coords": {"latitude": 19.2065, "longitude": 72.8440},
        "description": "Underground main line leak reported near SV Road junction.",
        "status": "Open",
    },
    {
        "id": "sig_2003",
        "ward_id": "ward_17",
        "category": "Flood Risk",
        "severity": 9,  # CRITICAL 2
        "coords": {"latitude": 19.2010, "longitude": 72.8350},
        "description": "Low-lying area near Poisar river in Kandivali at immediate risk of seasonal overflow.",
        "status": "Open",
    },
    {
        "id": "sig_2004",
        "ward_id": "ward_17",
        "category": "Garbage Overflow",
        "severity": 4,
        "coords": {"latitude": 19.2080, "longitude": 72.8380},
        "description": "Waste bins cleaned and sanitized near Link Road commercial belt.",
        "status": "Closed",
    },
    {
        "id": "sig_2005",
        "ward_id": "ward_17",
        "category": "Hospital Capacity",
        "severity": 7,
        "coords": {"latitude": 19.2030, "longitude": 72.8410},
        "description": "High emergency room intake load at Shatabdi Municipal Hospital.",
        "status": "Open",
    },
    {
        "id": "sig_2006",
        "ward_id": "ward_17",
        "category": "Street Light Failure",
        "severity": 5,
        "coords": {"latitude": 19.2050, "longitude": 72.8490},
        "description": "Complete lane darkness due to circuit failures near Charkop Sector 2.",
        "status": "Open",
    },
    {
        "id": "sig_2007",
        "ward_id": "ward_17",
        "category": "Drainage Blockage",
        "severity": 6,
        "coords": {"latitude": 19.2025, "longitude": 72.8455},
        "description": "Sewage backup cleared at MG Road Sector 3.",
        "status": "Closed",
    },

    # WARD 09 (Borivali South)
    {
        "id": "sig_3001",
        "ward_id": "ward_09",
        "category": "Water Leakage",
        "severity": 7,
        "coords": {"latitude": 19.2270, "longitude": 72.8580},
        "description": "Supply pressure drop across IC Colony main header pipeline.",
        "status": "Open",
    },
    {
        "id": "sig_3002",
        "ward_id": "ward_09",
        "category": "Traffic Congestion",
        "severity": 6,
        "coords": {"latitude": 19.2240, "longitude": 72.8610},
        "description": "Chronic traffic bottlenecking at Borivali Station East auto stand.",
        "status": "Open",
    },
    {
        "id": "sig_3003",
        "ward_id": "ward_09",
        "category": "Illegal Dumping",
        "severity": 5,
        "coords": {"latitude": 19.2215, "longitude": 72.8655},
        "description": "Debris pile in front of national park buffer area.",
        "status": "Open",
    },
    {
        "id": "sig_3004",
        "ward_id": "ward_09",
        "category": "School Maintenance",
        "severity": 4,
        "coords": {"latitude": 19.2260, "longitude": 72.8550},
        "description": "Structural roof repair completed at Borivali West Municipal School.",
        "status": "Closed",
    },
    {
        "id": "sig_3005",
        "ward_id": "ward_09",
        "category": "Park Maintenance",
        "severity": 3,
        "coords": {"latitude": 19.2290, "longitude": 72.8590},
        "description": "Fallen trees cleared and walkways cleaned at Veer Savarkar Udyan.",
        "status": "Closed",
    },
    {
        "id": "sig_3006",
        "ward_id": "ward_09",
        "category": "Drainage Blockage",
        "severity": 9,  # CRITICAL 3
        "coords": {"latitude": 19.2230, "longitude": 72.8670},
        "description": "Major storm drain blockage beneath Borivali East flyover junction, threat of flooding.",
        "status": "Open",
    },
    {
        "id": "sig_3007",
        "ward_id": "ward_09",
        "category": "Public Toilet Condition",
        "severity": 8,
        "coords": {"latitude": 19.2255, "longitude": 72.8625},
        "description": "Defunct water fixtures and poor sanitation at Shimpoli public toilet complex.",
        "status": "Open",
    },

    # WARD 22 (Dahisar West)
    {
        "id": "sig_4001",
        "ward_id": "ward_22",
        "category": "Road Damage",
        "severity": 7,
        "coords": {"latitude": 19.2470, "longitude": 72.8660},
        "description": "Asphalt peeling and potholes near Dahisar Toll Naka highway line.",
        "status": "Open",
    },
    {
        "id": "sig_4002",
        "ward_id": "ward_22",
        "category": "Flood Risk",
        "severity": 10, # CRITICAL 4
        "coords": {"latitude": 19.2440, "longitude": 72.8690},
        "description": "Dahisar river banks overflowing into nearby residential lanes.",
        "status": "Open",
    },
    {
        "id": "sig_4003",
        "ward_id": "ward_22",
        "category": "Street Light Failure",
        "severity": 4,
        "coords": {"latitude": 19.2410, "longitude": 72.8710},
        "description": "Damaged pole cables replaced near Dahisar East Railway bridge.",
        "status": "Closed",
    },
    {
        "id": "sig_4004",
        "ward_id": "ward_22",
        "category": "Garbage Overflow",
        "severity": 6,
        "coords": {"latitude": 19.2425, "longitude": 72.8645},
        "description": "Garbage accumulation blocking pedestrian pathway near Dahisar Market.",
        "status": "Open",
    },
    {
        "id": "sig_4005",
        "ward_id": "ward_22",
        "category": "Drainage Blockage",
        "severity": 8,
        "coords": {"latitude": 19.2480, "longitude": 72.8740},
        "description": "Culvert collapse blocking drain stream at Sudhir Phadke flyover.",
        "status": "Open",
    },
    {
        "id": "sig_4006",
        "ward_id": "ward_22",
        "category": "Water Leakage",
        "severity": 5,
        "coords": {"latitude": 19.2460, "longitude": 72.8780},
        "description": "Pipeline valve leak resolved at link road junction.",
        "status": "Closed",
    },

    # WARD 05 (Goregaon East)
    {
        "id": "sig_5001",
        "ward_id": "ward_05",
        "category": "Hospital Capacity",
        "severity": 8,
        "coords": {"latitude": 19.1670, "longitude": 72.8560},
        "description": "Overcrowding and lack of emergency stretchers at Goregaon Trauma Care Centre.",
        "status": "Open",
    },
    {
        "id": "sig_5002",
        "ward_id": "ward_05",
        "category": "Road Damage",
        "severity": 4,
        "coords": {"latitude": 19.1640, "longitude": 72.8580},
        "description": "Concrete lane repairs completed near Aarey Colony Unit 5.",
        "status": "Closed",
    },
    {
        "id": "sig_5003",
        "ward_id": "ward_05",
        "category": "Traffic Congestion",
        "severity": 5,
        "coords": {"latitude": 19.1610, "longitude": 72.8620},
        "description": "Massive choke-point under Goregaon Station East bridge during peak hours.",
        "status": "Open",
    },
    {
        "id": "sig_5004",
        "ward_id": "ward_05",
        "category": "School Maintenance",
        "severity": 6,
        "coords": {"latitude": 19.1690, "longitude": 72.8660},
        "description": "Broken boundary walls exposing municipal playground to highway traffic.",
        "status": "Open",
    },
    {
        "id": "sig_5005",
        "ward_id": "ward_05",
        "category": "Public Toilet Condition",
        "severity": 4,
        "coords": {"latitude": 19.1650, "longitude": 72.8720},
        "description": "Public toilet blocks renovated and sanitized near Hub Mall corridor.",
        "status": "Closed",
    },
]

# ---------------------------------------------------------------------------
# HISTORICAL MISSIONS (16 missions spanning different dates and outcomes)
# ---------------------------------------------------------------------------
HISTORICAL_MISSIONS: list[dict[str, Any]] = [
    {
        "id": "hist_01",
        "command": "Repair damaged roads and potholes in Kandivali West ward 17",
        "is_implemented": True,
        "days_ago": 58,
        "selected_plan_payload": {
            "mission_id": "miss_hist_01",
            "command_summary": "Arterial road restoration and asphalt overlay for MG Road, Kandivali West.",
            "briefs": [
                {
                    "mission_id": "miss_hist_01_brief",
                    "mission": "Pothole Resurfacing MG Road Segment",
                    "priority": "HIGH",
                    "budget": 1250000,
                    "impact_score": 88,
                    "confidence": 95,
                    "confidence_explanation": "Verified road density and high traffic volume on Link Road arterial routes.",
                    "beneficiaries": 18500,
                    "estimated_completion": "7 Days",
                    "department": "Roads & Traffic",
                    "evidence": ["sig_2001"],
                    "risks": "Monsoon rain delays and temporary lane closures.",
                    "action_items": [
                        "Examine coordinates for underground gas lines",
                        "Excavate loose asphalt and prepare dry sub-base",
                        "Lay hot-mix asphalt concrete and compact"
                    ],
                    "success_metrics": [
                        "Zero potholes reported along target 500m section",
                        "Average vehicle speed restored to 40 km/h"
                    ],
                    "timeline_decay_rate": 0.05,
                    "alternative": "Temporary cold-mix application (short durability)."
                }
            ]
        }
    },
    {
        "id": "hist_02",
        "command": "Clear drainage blockages to prevent flooding in Malad East ward 14",
        "is_implemented": True,
        "days_ago": 55,
        "selected_plan_payload": {
            "mission_id": "miss_hist_02",
            "command_summary": "Silt removal and structural storm water drain clearing behind Malad East Station.",
            "briefs": [
                {
                    "mission_id": "miss_hist_02_brief",
                    "mission": "Storm Drain Desilting and Rehabilitation",
                    "priority": "HIGH",
                    "budget": 850000,
                    "impact_score": 92,
                    "confidence": 96,
                    "confidence_explanation": "Flow-rate mapping highlights high silt risk blocking station exits.",
                    "beneficiaries": 32000,
                    "estimated_completion": "5 Days",
                    "department": "Storm Water Drains",
                    "evidence": ["sig_1006"],
                    "risks": "Underground heavy sewage gas accumulation.",
                    "action_items": [
                        "Deploy high-suction vacuum desilting machines",
                        "Remove solid plastic waste and debris manually",
                        "Install iron protective screens at catchment points"
                    ],
                    "success_metrics": [
                        "Storm water flow capacity increased by 150%",
                        "Eliminated track flooding during peak rainfall"
                    ],
                    "timeline_decay_rate": 0.04,
                    "alternative": "Manual cleaning only (highly inefficient, higher hazard)."
                }
            ]
        }
    },
    {
        "id": "hist_03",
        "command": "Fix broken street lights near Appa Pada in Malad East",
        "is_implemented": True,
        "days_ago": 52,
        "selected_plan_payload": {
            "mission_id": "miss_hist_03",
            "command_summary": "Sub-station circuit rewiring and LED streetlight deployment at Appa Pada.",
            "briefs": [
                {
                    "mission_id": "miss_hist_03_brief",
                    "mission": "Appa Pada Streetlight Restoration",
                    "priority": "MEDIUM",
                    "budget": 350000,
                    "impact_score": 75,
                    "confidence": 94,
                    "confidence_explanation": "Direct connection between lighting density and neighborhood safety metrics.",
                    "beneficiaries": 12000,
                    "estimated_completion": "3 Days",
                    "department": "Electrical & Energy",
                    "evidence": ["sig_1004"],
                    "risks": "Narrow lanes restricting ladder vehicle entry.",
                    "action_items": [
                        "Replace corroded electrical cables and wiring poles",
                        "Install 42 high-efficiency LED luminaires",
                        "Mount automatic photo-sensor switches on main poles"
                    ],
                    "success_metrics": [
                        "Light levels increased to standard 20 lux minimum",
                        "Complete elimination of dark spots on residential paths"
                    ],
                    "timeline_decay_rate": 0.03,
                    "alternative": "Individual bulb replacement without wire overhaul (leads to recurring trips)."
                }
            ]
        }
    },
    {
        "id": "hist_04",
        "command": "Inspect and repair transformer units in Kandivali West ward 17",
        "is_implemented": False,
        "days_ago": 48,
        "selected_plan_payload": {
            "mission_id": "miss_hist_04",
            "command_summary": "Thermal imaging and circuit breaker overhaul at Charkop electrical node.",
            "briefs": [
                {
                    "mission_id": "miss_hist_04_brief",
                    "mission": "Charkop Electrical Node Overhaul",
                    "priority": "MEDIUM",
                    "budget": 600000,
                    "impact_score": 78,
                    "confidence": 91,
                    "confidence_explanation": "Load logs indicate persistent peak demand overloading.",
                    "beneficiaries": 8500,
                    "estimated_completion": "4 Days",
                    "department": "Electrical & Energy",
                    "evidence": ["sig_2006"],
                    "risks": "Grid shutdown required for 4-hour slots during inspection.",
                    "action_items": [
                        "Perform thermal scan on substation transformer",
                        "Replace worn circuit breakers and isolator switches",
                        "Upgrade oil cooling system and filters"
                    ],
                    "success_metrics": [
                        "Zero voltage fluctuations reported post-rehab",
                        "Transformer operational temperature reduced by 15C"
                    ],
                    "timeline_decay_rate": 0.05,
                    "alternative": "Load-shedding rotation (highly disruptive to residents)."
                }
            ]
        }
    },
    {
        "id": "hist_05",
        "command": "Renovate Shimpoli public toilet complex in Borivali South",
        "is_implemented": True,
        "days_ago": 44,
        "selected_plan_payload": {
            "mission_id": "miss_hist_05",
            "command_summary": "Sanitation system renovation and main water line plumbing overhaul at Shimpoli.",
            "briefs": [
                {
                    "mission_id": "miss_hist_05_brief",
                    "mission": "Shimpoli Toilet Rehabilitation",
                    "priority": "HIGH",
                    "budget": 950000,
                    "impact_score": 86,
                    "confidence": 93,
                    "confidence_explanation": "Direct survey of sanitation facilities indicates high public utilization.",
                    "beneficiaries": 14000,
                    "estimated_completion": "6 Days",
                    "department": "Sanitation & Hygiene",
                    "evidence": ["sig_3007"],
                    "risks": "Temporary toilet relocation logistics for community.",
                    "action_items": [
                        "Replace corroded galvanized water piping with UPVC",
                        "Install sanitary fixtures, washbasins, and flush tanks",
                        "Connect toilet outlet directly to municipal sewer line"
                    ],
                    "success_metrics": [
                        "Consistent 24/7 pressurized water supply restored",
                        "Reduction in neighborhood hygiene complaints"
                    ],
                    "timeline_decay_rate": 0.04,
                    "alternative": "Patch repair of valves without main pipe overhaul."
                }
            ]
        }
    },
    {
        "id": "hist_06",
        "command": "Clear fallen trees and debris from Borivali South parks ward 09",
        "is_implemented": True,
        "days_ago": 40,
        "selected_plan_payload": {
            "mission_id": "miss_hist_06",
            "command_summary": "Debris removal and walkway restoration at Veer Savarkar Udyan.",
            "briefs": [
                {
                    "mission_id": "miss_hist_06_brief",
                    "mission": "Veer Savarkar Udyan Cleanup",
                    "priority": "LOW",
                    "budget": 180000,
                    "impact_score": 62,
                    "confidence": 97,
                    "confidence_explanation": "Simple logs of fallen foliage obstructing public paths.",
                    "beneficiaries": 4500,
                    "estimated_completion": "2 Days",
                    "department": "Gardens & Parks",
                    "evidence": ["sig_3005"],
                    "risks": "Minor walkway closures for safety during tree cutting.",
                    "action_items": [
                        "Cut and trim heavy tree trunks blocking pathways",
                        "Collect and haul organic waste to processing plant",
                        "Repair damaged walkway tiles and benches"
                    ],
                    "success_metrics": [
                        "All walking paths cleared of organic debris",
                        "Public access restored to all sections of park"
                    ],
                    "timeline_decay_rate": 0.02,
                    "alternative": "Let debris decompose naturally (creates safety hazards)."
                }
            ]
        }
    },
    {
        "id": "hist_07",
        "command": "Deploy sanitation team to clean commercial bins on Link Road in Kandivali",
        "is_implemented": True,
        "days_ago": 36,
        "selected_plan_payload": {
            "mission_id": "miss_hist_07",
            "command_summary": "Sanitation clearing and high-pressure chemical wash of Link Road bins.",
            "briefs": [
                {
                    "mission_id": "miss_hist_07_brief",
                    "mission": "Link Road Waste Clearing",
                    "priority": "MEDIUM",
                    "budget": 240000,
                    "impact_score": 79,
                    "confidence": 95,
                    "confidence_explanation": "Commercial density correlates with higher waste generation rates.",
                    "beneficiaries": 9800,
                    "estimated_completion": "1 Day",
                    "department": "Solid Waste Management",
                    "evidence": ["sig_2004"],
                    "risks": "Traffic bottlenecking on Link Road during clearing.",
                    "action_items": [
                        "Deploy mechanical dumper placer for swift loading",
                        "Clean bin surroundings with disinfectant solutions",
                        "Reposition bins closer to pickup-friendly zones"
                    ],
                    "success_metrics": [
                        "Complete clearance of overflowing waste within 12 hours",
                        "Zero complaints of organic odor from nearby shops"
                    ],
                    "timeline_decay_rate": 0.06,
                    "alternative": "Manual collection (slow, causes traffic blocks during day)."
                }
            ]
        }
    },
    {
        "id": "hist_08",
        "command": "Repair structural roof damage at Borivali West Municipal School",
        "is_implemented": True,
        "days_ago": 32,
        "selected_plan_payload": {
            "mission_id": "miss_hist_08",
            "command_summary": "Roof waterproofing, concrete patch work, and reinforcing beams at Municipal School.",
            "briefs": [
                {
                    "mission_id": "miss_hist_08_brief",
                    "mission": "School Roof Structural Repair",
                    "priority": "HIGH",
                    "budget": 1400000,
                    "impact_score": 90,
                    "confidence": 94,
                    "confidence_explanation": "Engineering assessment confirmed plaster delamination from structural slabs.",
                    "beneficiaries": 1100,
                    "estimated_completion": "8 Days",
                    "department": "School Infrastructure",
                    "evidence": ["sig_3004"],
                    "risks": "Work must be scheduled outside school hours for safety.",
                    "action_items": [
                        "Strip damaged plaster and clean exposed rebar",
                        "Apply anti-rust chemical coating to steel reinforcement",
                        "Lay high-strength concrete plaster and waterproof coat"
                    ],
                    "success_metrics": [
                        "Eliminated structural leakages in classrooms",
                        "Structural integrity certificate issued by civil engineer"
                    ],
                    "timeline_decay_rate": 0.03,
                    "alternative": "Temporary tar sheet covering (fails under heavy rains)."
                }
            ]
        }
    },
    {
        "id": "hist_09",
        "command": "Clear illegal debris dumping near SGNP boundary in Malad East",
        "is_implemented": False,
        "days_ago": 28,
        "selected_plan_payload": {
            "mission_id": "miss_hist_09",
            "command_summary": "Removal of debris and installation of concrete boundary fences near national park.",
            "briefs": [
                {
                    "mission_id": "miss_hist_09_brief",
                    "mission": "SGNP Boundary Debris Removal",
                    "priority": "HIGH",
                    "budget": 780000,
                    "impact_score": 82,
                    "confidence": 92,
                    "confidence_explanation": "Forest department records indicate high frequency of night dumping.",
                    "beneficiaries": 7500,
                    "estimated_completion": "4 Days",
                    "department": "Encroachment & Forest Link",
                    "evidence": ["sig_1005"],
                    "risks": "Encroachers resisting cleanup operations.",
                    "action_items": [
                        "Remove dumped concrete and bricks using heavy loaders",
                        "Level and plant native saplings along the edge",
                        "Erect 2m high precast concrete fencing"
                    ],
                    "success_metrics": [
                        "Zero debris detected inside forest boundary zone",
                        "Installation of permanent warning CCTV cameras"
                    ],
                    "timeline_decay_rate": 0.05,
                    "alternative": "Simple clearing without fence (debris returns in 48 hours)."
                }
            ]
        }
    },
    {
        "id": "hist_10",
        "command": "Resolve emergency room capacity constraints at Shatabdi Municipal Hospital",
        "is_implemented": True,
        "days_ago": 25,
        "selected_plan_payload": {
            "mission_id": "miss_hist_10",
            "command_summary": "Triage zone expansion, stretcher acquisition, and duty roster optimization.",
            "briefs": [
                {
                    "mission_id": "miss_hist_10_brief",
                    "mission": "Shatabdi ER Triage Expansion",
                    "priority": "HIGH",
                    "budget": 2800000,
                    "impact_score": 94,
                    "confidence": 95,
                    "confidence_explanation": "Wait time analysis reveals peak bottle-necking at basic check-in.",
                    "beneficiaries": 42000,
                    "estimated_completion": "10 Days",
                    "department": "Public Health & Safety",
                    "evidence": ["sig_2005"],
                    "risks": "Disruption of active patient receiving flows during construction.",
                    "action_items": [
                        "Demolish interior partitions to expand triage lobby",
                        "Procure 15 heavy-duty hydraulic stretchers",
                        "Deploy digital queue management display system"
                    ],
                    "success_metrics": [
                        "Average patient check-in wait time reduced by 40%",
                        "Zero stretcher shortage incidents in emergency bay"
                    ],
                    "timeline_decay_rate": 0.04,
                    "alternative": "Redirecting ambulances to other wards (extends transit risks)."
                }
            ]
        }
    },
    {
        "id": "hist_11",
        "command": "Address seasonal water supply shortages in Dahisar West ward 22",
        "is_implemented": True,
        "days_ago": 22,
        "selected_plan_payload": {
            "mission_id": "miss_hist_11",
            "command_summary": "New booster pump installation and main line connection at Dahisar West.",
            "briefs": [
                {
                    "mission_id": "miss_hist_11_brief",
                    "mission": "Dahisar West Booster Pump Installation",
                    "priority": "HIGH",
                    "budget": 1650000,
                    "impact_score": 89,
                    "confidence": 94,
                    "confidence_explanation": "Topographical logs explain elevation-induced pressure drop.",
                    "beneficiaries": 24000,
                    "estimated_completion": "6 Days",
                    "department": "Water Supply & Hydraulic",
                    "evidence": ["sig_4006"],
                    "risks": "Temporary supply suspension during booster coupling.",
                    "action_items": [
                        "Construct brick-and-mortar pump house chamber",
                        "Install twin 50HP centrifugal booster pumps",
                        "Integrate telemetry control panel with SCADA system"
                    ],
                    "success_metrics": [
                        "Static pressure increased by 1.2 bar at tail-end nodes",
                        "Consistent 2-hour daily supply window maintained"
                    ],
                    "timeline_decay_rate": 0.03,
                    "alternative": "Deploying water tankers daily (expensive, high recurring costs)."
                }
            ]
        }
    },
    {
        "id": "hist_12",
        "command": "Repair damaged roads and potholes near Dahisar Toll Naka",
        "is_implemented": True,
        "days_ago": 18,
        "selected_plan_payload": {
            "mission_id": "miss_hist_12",
            "command_summary": "Resurfacing and mastic asphalt patching at Toll Naka heavy traffic lanes.",
            "briefs": [
                {
                    "mission_id": "miss_hist_12_brief",
                    "mission": "Toll Naka Highway Line Resurfacing",
                    "priority": "HIGH",
                    "budget": 3400000,
                    "impact_score": 93,
                    "confidence": 96,
                    "confidence_explanation": "Highway toll lines experience high multi-axle truck loads.",
                    "beneficiaries": 85000,
                    "estimated_completion": "5 Days",
                    "department": "Roads & Traffic",
                    "evidence": ["sig_4001"],
                    "risks": "Severe highway traffic gridlock during night shifts.",
                    "action_items": [
                        "Scarify damaged concrete surfaces using road headers",
                        "Apply high-durability mastic asphalt concrete mix",
                        "Paint thermoplastic reflective lane lines"
                    ],
                    "success_metrics": [
                        "Complete restoration of toll approach lane leveling",
                        "Reduced average transit delays at toll gates"
                    ],
                    "timeline_decay_rate": 0.04,
                    "alternative": "Paver block installation (prone to sinking under truck loads)."
                }
            ]
        }
    },
    {
        "id": "hist_13",
        "command": "Address streetlight outages near Dahisar East Railway bridge",
        "is_implemented": True,
        "days_ago": 15,
        "selected_plan_payload": {
            "mission_id": "miss_hist_13",
            "command_summary": "Cabling replacement and pole-mounted LED installation near Railway bridge.",
            "briefs": [
                {
                    "mission_id": "miss_hist_13_brief",
                    "mission": "Railway Bridge Underpass Lighting",
                    "priority": "MEDIUM",
                    "budget": 280000,
                    "impact_score": 72,
                    "confidence": 93,
                    "confidence_explanation": "Passage under railway tracks is a key pedestrian path for commuters.",
                    "beneficiaries": 18000,
                    "estimated_completion": "2 Days",
                    "department": "Electrical & Energy",
                    "evidence": ["sig_4003"],
                    "risks": "Railway power lines require coordination.",
                    "action_items": [
                        "Pull new armored copper cables through conduits",
                        "Mount 15 weatherproof high-output LED fixtures",
                        "Test lighting illumination and grounding"
                    ],
                    "success_metrics": [
                        "Safe underpass transit levels restored for pedestrians",
                        "Zero dark zones along railway station approach path"
                    ],
                    "timeline_decay_rate": 0.03,
                    "alternative": "Basic wiring fix without protective conduits."
                }
            ]
        }
    },
    {
        "id": "hist_14",
        "command": "Clear sewage blockages near MG Road Sector 3 in Kandivali West",
        "is_implemented": True,
        "days_ago": 12,
        "selected_plan_payload": {
            "mission_id": "miss_hist_14",
            "command_summary": "High pressure jetting and chamber clearing on MG Road sewage line.",
            "briefs": [
                {
                    "mission_id": "miss_hist_14_brief",
                    "mission": "MG Road Sewage Line Clearance",
                    "priority": "MEDIUM",
                    "budget": 420000,
                    "impact_score": 81,
                    "confidence": 94,
                    "confidence_explanation": "Blockage located at key collector intersection of MG Road.",
                    "beneficiaries": 15000,
                    "estimated_completion": "3 Days",
                    "department": "Storm Water Drains",
                    "evidence": ["sig_2007"],
                    "risks": "Risk of toxic gas backflow into residential connections.",
                    "action_items": [
                        "Open inspection chamber covers and vent gases safely",
                        "Apply high-pressure sewer jetting machine",
                        "Eradicate root intrusion using specialized cutters"
                    ],
                    "success_metrics": [
                        "Complete clearance of line backing and free flow",
                        "Elimination of sanitary backup at street level"
                    ],
                    "timeline_decay_rate": 0.05,
                    "alternative": "Manual rodding (ineffective against dense root blockages)."
                }
            ]
        }
    },
    {
        "id": "hist_15",
        "command": "Renovate public toilet blocks near Hub Mall in Goregaon East",
        "is_implemented": True,
        "days_ago": 8,
        "selected_plan_payload": {
            "mission_id": "miss_hist_15",
            "command_summary": "Toilet block reconstruction, piping installation, and cleaning cycles at Goregaon East.",
            "briefs": [
                {
                    "mission_id": "miss_hist_15_brief",
                    "mission": "Goregaon Hub Toilet Renovation",
                    "priority": "MEDIUM",
                    "budget": 820000,
                    "impact_score": 84,
                    "confidence": 95,
                    "confidence_explanation": "Footfall metrics are high due to proximity to railway station and mall.",
                    "beneficiaries": 22000,
                    "estimated_completion": "5 Days",
                    "department": "Sanitation & Hygiene",
                    "evidence": ["sig_5005"],
                    "risks": "Restricted space for construction material storage.",
                    "action_items": [
                        "Reconstruct internal brick dividers and partition doors",
                        "Install low-flow flushing valves and water basins",
                        "Hook up to primary water storage booster tanks"
                    ],
                    "success_metrics": [
                        "Daily sanitation maintenance schedule deployed",
                        "Uninterrupted clean running water supply verified"
                    ],
                    "timeline_decay_rate": 0.04,
                    "alternative": "Repairing cosmetic fixtures only (plumbing leaks remain)."
                }
            ]
        }
    },
    {
        "id": "hist_16",
        "command": "Repair concrete lanes in Aarey Colony Unit 5 in Goregaon East",
        "is_implemented": True,
        "days_ago": 5,
        "selected_plan_payload": {
            "mission_id": "miss_hist_16",
            "command_summary": "Cement concrete patching and gravel-base leveling at Aarey Unit 5 lanes.",
            "briefs": [
                {
                    "mission_id": "miss_hist_16_brief",
                    "mission": "Aarey Unit 5 Concrete Patching",
                    "priority": "MEDIUM",
                    "budget": 1100000,
                    "impact_score": 83,
                    "confidence": 96,
                    "confidence_explanation": "Heavy dairy transport trucks require rigid paving over asphalt.",
                    "beneficiaries": 6800,
                    "estimated_completion": "6 Days",
                    "department": "Roads & Traffic",
                    "evidence": ["sig_5002"],
                    "risks": "Curing time requires 7-day closure of target lanes.",
                    "action_items": [
                        "Excavate sinking soft clay sections and lay dry aggregates",
                        "Lay M35 grade ready-mix cement concrete",
                        "Apply curing compound and cure with wet gunny bags"
                    ],
                    "success_metrics": [
                        "Concrete compression strength test passing",
                        "Complete leveling of dairy transportation corridor"
                    ],
                    "timeline_decay_rate": 0.03,
                    "alternative": "Asphalt patching (highly prone to sinking in waterlogged forest soil)."
                }
            ]
        }
    }
]
