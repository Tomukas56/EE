import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from "typeorm"
import type { Relation } from "typeorm"
import { Connector } from "./Connector.js"

@Entity()
export class Station {
    @PrimaryGeneratedColumn("uuid")
    id!: string

    @Column()
    name!: string

    @Column({ nullable: true })
    operator_name!: string

    @Column()
    address!: string

    @Column({
        type: "geometry",
        spatialFeatureType: "Point",
        srid: 4326, // WGS84
        nullable: true
    })
    location: any // GeoJSON Point

    @Column({ default: true })
    is_public!: boolean

    @Column({ nullable: true })
    website!: string

    @Column({ nullable: true })
    phone!: string

    @Column({ nullable: true })
    opening_hours!: string

    @OneToMany(() => Connector, (connector) => connector.station, { cascade: true })
    connectors!: Relation<Connector[]>
}
