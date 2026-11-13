"""Consistent JSON error format: {"error": CODE, "message": text, "details": {...}}."""

from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.views import exception_handler


class Unreachable(APIException):
    status_code = status.HTTP_404_NOT_FOUND
    default_code = "UNREACHABLE"
    default_detail = "No valid route exists in the current road network."


class Conflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_code = "CONFLICT"
    default_detail = "The request conflicts with the current state."


class BadRequest(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "VALIDATION_ERROR"
    default_detail = "Invalid request."


_CODES = {
    400: "VALIDATION_ERROR",
    401: "UNAUTHORIZED",
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    405: "METHOD_NOT_ALLOWED",
    409: "CONFLICT",
    429: "THROTTLED",
}


def _first_message(data):
    if isinstance(data, list) and data:
        return _first_message(data[0])
    if isinstance(data, dict) and data:
        key, value = next(iter(data.items()))
        msg = _first_message(value)
        return msg if key in ("detail", "non_field_errors") else f"{key}: {msg}"
    return str(data)


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return None
    data = response.data
    if isinstance(exc, (Unreachable, Conflict, BadRequest)):
        code = exc.default_code
    else:
        code = _CODES.get(response.status_code, "ERROR")
    body = {"error": code, "message": _first_message(data)}
    if isinstance(exc, ValidationError) and isinstance(data, (dict, list)):
        body["details"] = data
    response.data = body
    return response
