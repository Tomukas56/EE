var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Station } from "./Station.js";
export var ConnectorType;
(function (ConnectorType) {
    ConnectorType["CCS"] = "CCS";
    ConnectorType["CHAdeMO"] = "CHAdeMO";
    ConnectorType["TYPE2"] = "Type 2";
    ConnectorType["TYPE1"] = "Type 1";
})(ConnectorType || (ConnectorType = {}));
export var ConnectorStatus;
(function (ConnectorStatus) {
    ConnectorStatus["AVAILABLE"] = "AVAILABLE";
    ConnectorStatus["OCCUPIED"] = "OCCUPIED";
    ConnectorStatus["CHARGING"] = "CHARGING";
    ConnectorStatus["OUTOFORDER"] = "OUTOFORDER";
    ConnectorStatus["UNKNOWN"] = "UNKNOWN";
})(ConnectorStatus || (ConnectorStatus = {}));
let Connector = class Connector {
    id;
    evse_id;
    type;
    max_power_kw;
    status;
    tariff;
    station;
};
__decorate([
    PrimaryGeneratedColumn("uuid"),
    __metadata("design:type", String)
], Connector.prototype, "id", void 0);
__decorate([
    Column(),
    __metadata("design:type", String)
], Connector.prototype, "evse_id", void 0);
__decorate([
    Column({
        type: "enum",
        enum: ConnectorType
    }),
    __metadata("design:type", String)
], Connector.prototype, "type", void 0);
__decorate([
    Column("decimal", { precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], Connector.prototype, "max_power_kw", void 0);
__decorate([
    Column({
        type: "enum",
        enum: ConnectorStatus,
        default: ConnectorStatus.UNKNOWN
    }),
    __metadata("design:type", String)
], Connector.prototype, "status", void 0);
__decorate([
    Column({ nullable: true }),
    __metadata("design:type", String)
], Connector.prototype, "tariff", void 0);
__decorate([
    ManyToOne(() => Station, (station) => station.connectors),
    __metadata("design:type", Object)
], Connector.prototype, "station", void 0);
Connector = __decorate([
    Entity()
], Connector);
export { Connector };
//# sourceMappingURL=Connector.js.map