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
@Entity()
export class Connector {
    @PrimaryGeneratedColumn("uuid")
    id;
    @Column()
    evse_id;
    @Column({
        type: "enum",
        enum: ConnectorType
    })
    type;
    @Column("decimal", { precision: 10, scale: 2 })
    max_power_kw;
    @Column({
        type: "enum",
        enum: ConnectorStatus,
        default: ConnectorStatus.UNKNOWN
    })
    status;
    @Column({ nullable: true })
    tariff;
    @ManyToOne(() => Station, (station) => station.connectors)
    station;
}
//# sourceMappingURL=Connector.js.map