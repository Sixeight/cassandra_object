CassandraObject::Type.register(:array,          CassandraObject::Types::ArrayType)
CassandraObject::Type.register(:boolean,        CassandraObject::Types::BooleanType)
CassandraObject::Type.register(:date,           CassandraObject::Types::DateType)
CassandraObject::Type.register(:float,          CassandraObject::Types::FloatType)
CassandraObject::Type.register(:integer,        CassandraObject::Types::IntegerType)
CassandraObject::Type.register(:json,           CassandraObject::Types::JsonType)
CassandraObject::Type.register(:time,           CassandraObject::Types::TimeType)
CassandraObject::Type.register(:time_with_zone, CassandraObject::Types::TimeWithZoneType)
CassandraObject::Type.register(:string,         CassandraObject::Types::StringType)
