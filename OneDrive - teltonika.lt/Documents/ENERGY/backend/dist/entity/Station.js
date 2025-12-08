var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from "typeorm";
import { Connector } from "./Connector.js";
let Station = class Station {
    id;
    name;
    operator_name;
    address;
    location; // GeoJSON Point
    is_public;
    website;
    phone;
    opening_hours;
    connectors;
};
__decorate([
    PrimaryGeneratedColumn("uuid"),
    __metadata("design:type", String)
], Station.prototype, "id", void 0);
__decorate([
    Column(),
    __metadata("design:type", String)
], Station.prototype, "name", void 0);
__decorate([
    Column({ nullable: true }),
    __metadata("design:type", String)
], Station.prototype, "operator_name", void 0);
__decorate([
    Column(),
    __metadata("design:type", String)
], Station.prototype, "address", void 0);
__decorate([
    Column({
        type: "geometry",
        spatialFeatureType: "Point",
        srid: 4326, // WGS84
        nullable: true
    }),
    __metadata("design:type", Object)
], Station.prototype, "location", void 0);
__decorate([
    Column({ default: true }),
    __metadata("design:type", Boolean)
], Station.prototype, "is_public", void 0);
__decorate([
    Column({ nullable: true }),
    __metadata("design:type", String)
], Station.prototype, "website", void 0);
__decorate([
    Column({ nullable: true }),
    __metadata("design:type", String)
], Station.prototype, "phone", void 0);
__decorate([
    Column({ nullable: true }),
    __metadata("design:type", String)
], Station.prototype, "opening_hours", void 0);
__decorate([
    OneToMany(() => Connector, (connector) => connector.station, { cascade: true }),
    __metadata("design:type", Array)
], Station.prototype, "connectors", void 0);
Station = __decorate([
    Entity()
], Station);
export { Station };
//# sourceMappingURL=Station.js.map