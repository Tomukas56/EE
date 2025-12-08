import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from "typeorm";
import { Connector } from "./Connector.js";
@Entity()
export class Station {
    @PrimaryGeneratedColumn("uuid")
    id;
    @Column()
    name;
    @Column({ nullable: true })
    operator_name;
    @Column()
    address;
    @Column({
        type: "geometry",
        spatialFeatureType: "Point",
        srid: 4326, // WGS84
        nullable: true
    })
    location; // GeoJSON Point
    @Column({ default: true })
    is_public;
    @Column({ nullable: true })
    website;
    @Column({ nullable: true })
    phone;
    @Column({ nullable: true })
    opening_hours;
    @OneToMany(() => Connector, (connector) => connector.station, { cascade: true })
    connectors;
}
//# sourceMappingURL=Station.js.map