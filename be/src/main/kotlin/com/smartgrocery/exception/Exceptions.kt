package com.smartgrocery.exception

enum class ErrorCode(val code: Int, val message: String) {
    // Success codes (1000-1099)
    SUCCESS(1000, "Success"),
    CREATED(1001, "Created successfully"),

    // Client errors (1100-1199)
    INVALID_REQUEST(1100, "Invalid request"),
    VALIDATION_ERROR(1101, "Validation error"),
    UNAUTHORIZED(1102, "Unauthorized"),
    FORBIDDEN(1103, "Forbidden"),
    NOT_FOUND(1104, "Resource not found"),
    CONFLICT(1105, "Resource conflict"),
    CONCURRENCY_ERROR(1106, "Concurrency conflict - resource was modified"),

    // Authentication errors (1200-1299)
    INVALID_CREDENTIALS(1200, "Invalid username or password"),
    TOKEN_EXPIRED(1201, "Token has expired"),
    TOKEN_INVALID(1202, "Invalid token"),
    ACCOUNT_DISABLED(1203, "Account is disabled"),

    // User errors (1300-1399)
    USER_NOT_FOUND(1300, "User not found"),
    USERNAME_ALREADY_EXISTS(1301, "Username already exists"),
    EMAIL_ALREADY_EXISTS(1302, "Email already exists"),
    PASSWORD_MISMATCH(1303, "Current password is incorrect"),

    // Family errors (1400-1499)
    FAMILY_NOT_FOUND(1400, "Family not found"),
    INVALID_INVITE_CODE(1401, "Invalid invite code"),
    ALREADY_MEMBER(1402, "User is already a member of this family"),
    NOT_A_MEMBER(1403, "User is not a member of this family"),
    NOT_FAMILY_LEADER(1404, "Only family leader can perform this action"),
    CANNOT_REMOVE_LEADER(1405, "Cannot remove the family leader"),

    // Shopping list errors (1500-1599)
    SHOPPING_LIST_NOT_FOUND(1500, "Shopping list not found"),
    SHOPPING_ITEM_NOT_FOUND(1501, "Shopping item not found"),
    INVALID_PRODUCT_SPECIFICATION(1502, "Either master product or custom product name must be specified"),

    // Fridge errors (1600-1699)
    FRIDGE_ITEM_NOT_FOUND(1600, "Fridge item not found"),
    INSUFFICIENT_QUANTITY(1601, "Insufficient quantity"),

    // Recipe errors (1700-1799)
    RECIPE_NOT_FOUND(1700, "Recipe not found"),

    // Meal plan errors (1800-1899)
    MEAL_PLAN_NOT_FOUND(1800, "Meal plan not found"),
    MEAL_PLAN_ALREADY_EXISTS(1801, "Meal plan already exists for this date and meal type"),
    MEAL_ITEM_NOT_FOUND(1802, "Meal item not found"),

    // Category/Product errors (1900-1999)
    CATEGORY_NOT_FOUND(1900, "Category not found"),
    PRODUCT_NOT_FOUND(1901, "Product not found"),

    // Friendship errors (2000-2099)
    FRIENDSHIP_NOT_FOUND(2000, "Friendship not found"),
    FRIEND_REQUEST_ALREADY_EXISTS(2001, "Friend request already exists"),
    CANNOT_SEND_REQUEST_TO_SELF(2002, "Cannot send friend request to yourself"),
    NOT_FRIENDS(2003, "You are not friends with this user"),
    ALREADY_FRIENDS(2004, "You are already friends with this user"),
    FRIEND_REQUEST_NOT_PENDING(2005, "Friend request is not pending"),
    NOT_YOUR_FRIEND_REQUEST(2006, "This friend request is not for you"),

    // Family invitation errors (2100-2199)
    FAMILY_INVITATION_NOT_FOUND(2100, "Family invitation not found"),
    NOT_INVITED_TO_FAMILY(2101, "You are not invited to this family"),
    INVITATION_NOT_PENDING(2102, "Invitation is not pending"),
    MUST_INVITE_AT_LEAST_ONE_FRIEND(2103, "Must invite at least one friend when creating a family"),
    CAN_ONLY_INVITE_FRIENDS(2104, "You can only invite your friends"),

    // File errors (2200-2299)
    FILE_NOT_FOUND(2200, "File not found"),
    FILE_UPLOAD_FAILED(2201, "File upload failed"),
    INVALID_FILE_TYPE(2202, "Invalid file type"),
    FILE_TOO_LARGE(2203, "File is too large"),

    // Notification errors (2300-2399)
    NOTIFICATION_NOT_FOUND(2300, "Notification not found"),

    // Server errors (5000+)
    INTERNAL_ERROR(5000, "Internal server error")
}

open class ApiException(
    val errorCode: ErrorCode,
    override val message: String = errorCode.message
) : RuntimeException(message)

class ResourceNotFoundException(
    errorCode: ErrorCode = ErrorCode.NOT_FOUND,
    message: String = errorCode.message
) : ApiException(errorCode, message)

class ValidationException(
    message: String = ErrorCode.VALIDATION_ERROR.message
) : ApiException(ErrorCode.VALIDATION_ERROR, message)

class UnauthorizedException(
    message: String = ErrorCode.UNAUTHORIZED.message
) : ApiException(ErrorCode.UNAUTHORIZED, message)

class ForbiddenException(
    message: String = ErrorCode.FORBIDDEN.message
) : ApiException(ErrorCode.FORBIDDEN, message)

class ConflictException(
    errorCode: ErrorCode = ErrorCode.CONFLICT,
    message: String = errorCode.message
) : ApiException(errorCode, message)

class ConcurrencyException(
    message: String = ErrorCode.CONCURRENCY_ERROR.message
) : ApiException(ErrorCode.CONCURRENCY_ERROR, message)

class AuthenticationException(
    errorCode: ErrorCode = ErrorCode.INVALID_CREDENTIALS,
    message: String = errorCode.message
) : ApiException(errorCode, message)

