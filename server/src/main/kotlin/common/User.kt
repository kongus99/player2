package common

import com.jooq.generated.tables.records.UserRecord


object User {

    data class UserData(val id: Int, val username: String, val email: String)

    data class UserToCreate(val username: String, val email: String, val password: String)

    fun fromRecord(record: UserRecord) =
            UserData(record.id, record.name, record.email)
}
