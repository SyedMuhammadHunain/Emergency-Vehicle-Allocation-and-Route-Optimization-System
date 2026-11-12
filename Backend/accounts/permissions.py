from rest_framework.permissions import BasePermission

from .models import Role


class HasRole(BasePermission):
    """Usage: permission_classes = [HasRole.of(Role.ADMIN, Role.DISPATCHER)]"""

    roles = ()
    message = "You do not have permission for this action."

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.role in self.roles)

    @classmethod
    def of(cls, *roles):
        return type(f"HasRole_{'_'.join(roles)}", (cls,), {"roles": tuple(roles)})


IsAdmin = HasRole.of(Role.ADMIN)
IsDispatcherOrAdmin = HasRole.of(Role.DISPATCHER, Role.ADMIN)
IsStaffRole = HasRole.of(Role.DISPATCHER, Role.ADMIN, Role.DRIVER)
