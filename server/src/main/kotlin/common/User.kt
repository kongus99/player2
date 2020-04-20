package common

import com.jooq.generated.tables.records.UserRecord
import javax.validation.constraints.Email
import javax.validation.constraints.Pattern


object User {

    data class UserData(val id: Int, val username: String, val email: String)


    data class UserToCreate(
            @get:Pattern(regexp = "^[a-zA-Z0-9_-]{3,15}$",
                    message = "Lower and upper case letters, numbers, - and _, min 3 and max 15 chars.")
            val username: String,
            @get:Email(message = "Valid email needed.")
            val email: String,
            @get:Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$",
                    message = "Minimum eight characters, at least one uppercase letter, one lowercase letter, one number and one special character.")
            val password: String
    )

    fun fromRecord(record: UserRecord) =
            UserData(record.id, record.name, record.email)
}
