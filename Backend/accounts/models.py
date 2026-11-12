from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class Role(models.TextChoices):
    CITIZEN = "citizen", "Citizen"
    DISPATCHER = "dispatcher", "Dispatcher"
    DRIVER = "driver", "Driver"
    ADMIN = "admin", "Admin"


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email, password=None, **extra):
        if not email:
            raise ValueError("Email is required.")
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra):
        extra.setdefault("role", Role.ADMIN)
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        extra.setdefault("name", "System Administrator")
        return self.create_user(email, password, **extra)


class User(AbstractBaseUser, PermissionsMixin):
    """Login is by email (matches the Flutter login screen)."""

    email = models.EmailField(unique=True)
    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=30, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CITIZEN, db_index=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)  # Django admin site access
    created_at = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["name"]

    class Meta:
        db_table = "users"
        ordering = ["id"]

    def __str__(self):
        return f"{self.name} <{self.email}> ({self.role})"

    @property
    def code(self):
        prefix = {"citizen": "CIT", "dispatcher": "DIS", "driver": "DRV", "admin": "ADM"}[self.role]
        return f"USR-{prefix}-{self.id:03d}"
