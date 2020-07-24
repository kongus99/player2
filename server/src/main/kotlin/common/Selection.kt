package common

import javax.validation.Constraint
import javax.validation.ConstraintValidator
import javax.validation.ConstraintValidatorContext
import javax.validation.Payload
import javax.validation.constraints.Pattern
import kotlin.reflect.KClass

object Selection {
    @MustBeDocumented
    @Constraint(validatedBy = [StartsValidator::class])
    @Target(AnnotationTarget.FUNCTION, AnnotationTarget.FIELD, AnnotationTarget.PROPERTY_GETTER)
    @Retention(AnnotationRetention.RUNTIME)
    annotation class StartsValid(val message: String = "Selection should be correct",
                                 val groups: Array<KClass<*>> = [],
                                 val payload: Array<KClass<out Payload>> = [])

    class StartsValidator : ConstraintValidator<StartsValid, List<Double>> {
        override fun initialize(contactNumber: StartsValid) {}

        override fun isValid(starts: List<Double>,
                             cxt: ConstraintValidatorContext): Boolean {
            return starts.min()!! >= 0.0 &&
                    starts.toSet().toList() == starts
        }
    }

    data class Selection(val id: Int, val userId: Int, val videoId: Int,
                         @get:Pattern(regexp = "^[a-zA-Z0-9_-]{3,50}$",
                                 message = "Lower and upper case letters, numbers, - and _, min 3 and max 50 chars.")
                         val title: String,
                         @get:StartsValid val
                         starts: List<Double>)
}
