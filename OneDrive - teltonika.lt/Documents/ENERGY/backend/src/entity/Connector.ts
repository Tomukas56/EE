import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm"
import { Station } from "./Station.js"

export enum ConnectorType {
    CCS = "CCS",
    CHAdeMO = "CHAdeMO",
    TYPE2 = "Type 2",
    TYPE1 = "Type 1"
}

export enum ConnectorStatus {
    AVAILABLE = "AVAILABLE",
    OCCUPIED = "OCCUPIED",
    CHARGING = "CHARGING",
    OUTOFORDER = "OUTOFORDER",
    UNKNOWN = "UNKNOWN"
}

@Entity()
export class Connector {
    @PrimaryGeneratedColumn("uuid")
    id!: string

    @Column()
    evse_id!: string

    @Column({
        type: "enum",
        enum: ConnectorType
    })
    type!: ConnectorType

    @Column("decimal", { precision: 10, scale: 2 })
    max_power_kw!: number

    @Column({
        type: "enum",
        enum: ConnectorStatus,
        default: ConnectorStatus.UNKNOWN
    })
    status!: ConnectorStatus

    @Column({ nullable: true })
    tariff!: string

    @ManyToOne(() => Station, (station) => station.connectors)
    station!: Station
}
