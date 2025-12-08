// Mock connector types matching Prisma schema
export var ConnectorType;
(function (ConnectorType) {
    ConnectorType["CCS"] = "CCS";
    ConnectorType["CHAdeMO"] = "CHAdeMO";
    ConnectorType["TYPE2"] = "TYPE2";
    ConnectorType["TYPE1"] = "TYPE1";
})(ConnectorType || (ConnectorType = {}));
export var ConnectorStatus;
(function (ConnectorStatus) {
    ConnectorStatus["AVAILABLE"] = "AVAILABLE";
    ConnectorStatus["OCCUPIED"] = "OCCUPIED";
    ConnectorStatus["CHARGING"] = "CHARGING";
    ConnectorStatus["OUTOFORDER"] = "OUTOFORDER";
    ConnectorStatus["UNKNOWN"] = "UNKNOWN";
})(ConnectorStatus || (ConnectorStatus = {}));
export class CPOService {
    /**
     * Mock CPO API - simulates fetching station data from external provider
     */
    async fetchStations() {
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500));
        return [
            {
                name: "Ignitis Charging Hub - Vilnius Center",
                operator_name: "Ignitis",
                address: "Konstitucijos pr. 20, Vilnius",
                latitude: 54.6872,
                longitude: 25.2797,
                is_public: true,
                website: "https://ignitis.lt",
                phone: "+370 700 55 055",
                opening_hours: "24/7",
                connectors: [
                    {
                        evse_id: "LT*IGN*E001*1",
                        type: ConnectorType.CCS,
                        max_power_kw: 150,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.35 EUR/kWh"
                    },
                    {
                        evse_id: "LT*IGN*E001*2",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 22,
                        status: ConnectorStatus.CHARGING,
                        tariff: "0.25 EUR/kWh"
                    }
                ]
            },
            {
                name: "Elinta Fast Charge - Kaunas",
                operator_name: "Elinta",
                address: "Savanorių pr. 255, Kaunas",
                latitude: 54.9027,
                longitude: 23.9570,
                is_public: true,
                website: "https://elinta.lt",
                phone: "+370 37 301 111",
                opening_hours: "24/7",
                connectors: [
                    {
                        evse_id: "LT*ELN*K002*1",
                        type: ConnectorType.CCS,
                        max_power_kw: 50,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.30 EUR/kWh"
                    },
                    {
                        evse_id: "LT*ELN*K002*2",
                        type: ConnectorType.CHAdeMO,
                        max_power_kw: 50,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.30 EUR/kWh"
                    }
                ]
            },
            {
                name: "Maxima Shopping Center Charger",
                operator_name: "Maxima",
                address: "Ozo g. 25, Vilnius",
                latitude: 54.7104,
                longitude: 25.2799,
                is_public: true,
                website: "https://maxima.lt",
                opening_hours: "08:00-22:00",
                connectors: [
                    {
                        evse_id: "LT*MAX*V003*1",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 22,
                        status: ConnectorStatus.OCCUPIED,
                        tariff: "Free"
                    },
                    {
                        evse_id: "LT*MAX*V003*2",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 22,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "Free"
                    }
                ]
            },
            {
                name: "Tesla Supercharger - Vilnius",
                operator_name: "Tesla",
                address: "Ukmergės g. 369A, Vilnius",
                latitude: 54.7290,
                longitude: 25.2906,
                is_public: false,
                website: "https://tesla.com",
                phone: "+370 800 00 000",
                opening_hours: "24/7",
                connectors: [
                    {
                        evse_id: "LT*TSL*V004*1",
                        type: ConnectorType.CCS,
                        max_power_kw: 250,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.40 EUR/kWh"
                    },
                    {
                        evse_id: "LT*TSL*V004*2",
                        type: ConnectorType.CCS,
                        max_power_kw: 250,
                        status: ConnectorStatus.CHARGING,
                        tariff: "0.40 EUR/kWh"
                    },
                    {
                        evse_id: "LT*TSL*V004*3",
                        type: ConnectorType.CCS,
                        max_power_kw: 250,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.40 EUR/kWh"
                    }
                ]
            },
            {
                name: "Ignitis Green Energy Hub",
                operator_name: "Ignitis",
                address: "Žirmūnų g. 139, Vilnius",
                latitude: 54.7022,
                longitude: 25.2904,
                is_public: true,
                website: "https://ignitis.lt",
                phone: "+370 700 55 055",
                opening_hours: "24/7",
                connectors: [
                    {
                        evse_id: "LT*IGN*E005*1",
                        type: ConnectorType.CCS,
                        max_power_kw: 150,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.35 EUR/kWh"
                    },
                    {
                        evse_id: "LT*IGN*E005*2",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 22,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.25 EUR/kWh"
                    }
                ]
            },
            {
                name: "Elinta Downtown Kaunas",
                operator_name: "Elinta",
                address: "Laisvės al. 53, Kaunas",
                latitude: 54.8967,
                longitude: 23.9157,
                is_public: true,
                phone: "+370 37 301 111",
                opening_hours: "06:00-23:00",
                connectors: [
                    {
                        evse_id: "LT*ELN*K006*1",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 11,
                        status: ConnectorStatus.AVAILABLE,
                        tariff: "0.20 EUR/kWh"
                    }
                ]
            },
            {
                name: "LIDL Parking Charger",
                operator_name: "LIDL",
                address: "Ukmergės g. 282, Vilnius",
                latitude: 54.7250,
                longitude: 25.2856,
                is_public: true,
                opening_hours: "07:00-22:00",
                connectors: [
                    {
                        evse_id: "LT*LDL*V007*1",
                        type: ConnectorType.TYPE2,
                        max_power_kw: 22,
                        status: ConnectorStatus.OUTOFORDER,
                        tariff: "Free"
                    }
                ]
            }
        ];
    }
}
//# sourceMappingURL=CPOService.js.map