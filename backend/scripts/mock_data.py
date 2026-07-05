"""
Mock dataset definitions for CivicTwin AI.

Isolated from `seed_database.py` execution logic so the dataset itself can be
reviewed, extended, or swapped independently of the seeding mechanism
(per ADR Document 07: "Isolated Mock Dataset Files").

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
    "total_budget_allocated": 50_000_000,  # ₹5 Crore MPLADS baseline pool
    "budget_utilized": 8_500_000,
    "center": {"latitude": 19.1154, "longitude": 72.8624},
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
# constituencies/const_mumbai_north/signals
# ---------------------------------------------------------------------------
SIGNALS: list[dict[str, Any]] = [
    {
        "id": "sig_8829",
        "ward_id": "ward_14",
        "category": "Water",
        "severity": 9,
        "coords": {"latitude": 19.1830, "longitude": 72.8480},
        "description": "No piped drinking water supply for over 3 weeks in Malad East sector 4.",
        "status": "Open",
    },
    {
        "id": "sig_9102",
        "ward_id": "ward_14",
        "category": "Water",
        "severity": 8,
        "coords": {"latitude": 19.1810, "longitude": 72.8510},
        "description": "Contaminated borewell water reported near municipal school.",
        "status": "Open",
    },
    {
        "id": "sig_1102",
        "ward_id": "ward_14",
        "category": "Health",
        "severity": 7,
        "coords": {"latitude": 19.1795, "longitude": 72.8465},
        "description": "Rise in waterborne illness cases at local health post.",
        "status": "Open",
    },
    {
        "id": "sig_2201",
        "ward_id": "ward_17",
        "category": "Roads",
        "severity": 6,
        "coords": {"latitude": 19.2040, "longitude": 72.8460},
        "description": "Major potholes on arterial road causing traffic delays.",
        "status": "Open",
    },
    {
        "id": "sig_2245",
        "ward_id": "ward_17",
        "category": "Electricity",
        "severity": 5,
        "coords": {"latitude": 19.2065, "longitude": 72.8440},
        "description": "Frequent transformer trips in residential block C.",
        "status": "Open",
    },
    {
        "id": "sig_3310",
        "ward_id": "ward_09",
        "category": "Water",
        "severity": 7,
        "coords": {"latitude": 19.2270, "longitude": 72.8580},
        "description": "Low water pressure affecting upper-floor residents.",
        "status": "Open",
    },
    {
        "id": "sig_3355",
        "ward_id": "ward_09",
        "category": "Health",
        "severity": 4,
        "coords": {"latitude": 19.2240, "longitude": 72.8610},
        "description": "Request for additional primary health center staffing.",
        "status": "Closed",
    },
    {
        "id": "sig_4410",
        "ward_id": "ward_22",
        "category": "Roads",
        "severity": 8,
        "coords": {"latitude": 19.2470, "longitude": 72.8660},
        "description": "Collapsed drainage culvert blocking main access road.",
        "status": "Open",
    },
    {
        "id": "sig_4432",
        "ward_id": "ward_22",
        "category": "Water",
        "severity": 6,
        "coords": {"latitude": 19.2440, "longitude": 72.8690},
        "description": "Seasonal water shortage reported in Dahisar West sector 2.",
        "status": "Open",
    },
    {
        "id": "sig_5510",
        "ward_id": "ward_05",
        "category": "Electricity",
        "severity": 3,
        "coords": {"latitude": 19.1670, "longitude": 72.8560},
        "description": "Streetlight outages along Goregaon East main road.",
        "status": "Closed",
    },
    {
        "id": "sig_5533",
        "ward_id": "ward_05",
        "category": "Health",
        "severity": 5,
        "coords": {"latitude": 19.1640, "longitude": 72.8580},
        "description": "Overcrowding reported at ward health dispensary.",
        "status": "Open",
    },
]
