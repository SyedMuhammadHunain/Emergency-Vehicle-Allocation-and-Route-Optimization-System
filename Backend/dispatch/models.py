"""
Database schema (MySQL) for ResQ.

Core tables from the design document (section 5.2):
    emergency, vehicle, resource, road_node, road_edge, assignment
Added because the requirements / Flutter app need them:
    users (accounts app), plan, notification, notification_read,
    audit_log, vehicle_location_log, graph_version
"""

import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone

# ---------------------------------------------------------------------------
# Choices (values match the strings used by the Flutter app)
# ---------------------------------------------------------------------------


class EmergencyCategory(models.TextChoices):
    MEDICAL = "MEDICAL", "Medical"
    FIRE = "FIRE", "Fire"
    ACCIDENT = "ACCIDENT", "Accident"
    RESCUE = "RESCUE", "Rescue"


class EmergencyStatus(models.TextChoices):
    REPORTED = "REPORTED", "Reported (pending)"
    ASSIGNED = "ASSIGNED", "Assigned"
    EN_ROUTE = "EN_ROUTE", "En route"
    ON_SCENE = "ON_SCENE", "On scene"
    RESOLVED = "RESOLVED", "Resolved"
    CANCELLED = "CANCELLED", "Cancelled"


ACTIVE_EMERGENCY_STATUSES = [
    EmergencyStatus.REPORTED, EmergencyStatus.ASSIGNED,
    EmergencyStatus.EN_ROUTE, EmergencyStatus.ON_SCENE,
]


class VehicleType(models.TextChoices):
    AMBULANCE = "Ambulance", "Ambulance"
    FIRE_BRIGADE = "Fire Brigade", "Fire Brigade"
    RESCUE_VEHICLE = "Rescue Vehicle", "Rescue Vehicle"


class VehicleStatus(models.TextChoices):
    AVAILABLE = "Available", "Available"
    BUSY = "Busy", "Busy"
    EN_ROUTE = "En Route", "En Route"
    MAINTENANCE = "Maintenance", "Maintenance"


class ResourceCategory(models.TextChoices):
    CREW = "Crew", "Crew"
    EQUIPMENT = "Equipment", "Equipment"
    MEDICAL = "Medical", "Medical"
    FUEL = "Fuel", "Fuel"
    COMMUNICATION = "Communication", "Communication"


class ResourceStatus(models.TextChoices):
    AVAILABLE = "Available", "Available"
    IN_USE = "In Use", "In Use"
    DEPLETED = "Depleted", "Depleted"


# Which vehicle types can serve which emergency category (first = preferred).
COMPATIBLE_VEHICLE_TYPES = {
    EmergencyCategory.MEDICAL: (VehicleType.AMBULANCE, VehicleType.RESCUE_VEHICLE),
    EmergencyCategory.FIRE: (VehicleType.FIRE_BRIGADE,),
    EmergencyCategory.ACCIDENT: (VehicleType.AMBULANCE, VehicleType.RESCUE_VEHICLE),
    EmergencyCategory.RESCUE: (VehicleType.RESCUE_VEHICLE, VehicleType.FIRE_BRIGADE),
}

# Equipment category a vehicle must carry (quantity > 0) to serve the emergency.
REQUIRED_RESOURCE_CATEGORY = {
    EmergencyCategory.MEDICAL: ResourceCategory.MEDICAL,
    EmergencyCategory.FIRE: ResourceCategory.EQUIPMENT,
    EmergencyCategory.ACCIDENT: ResourceCategory.MEDICAL,
    EmergencyCategory.RESCUE: ResourceCategory.EQUIPMENT,
}


# ---------------------------------------------------------------------------
# Road network
# ---------------------------------------------------------------------------


class RoadNode(models.Model):
    name = models.CharField(max_length=120, blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()

    class Meta:
        db_table = "road_node"

    def __str__(self):
        return self.name or f"Node {self.id}"


class RoadEdge(models.Model):
    name = models.CharField(max_length=160, blank=True, db_index=True)
    from_node = models.ForeignKey(RoadNode, on_delete=models.CASCADE, related_name="out_edges")
    to_node = models.ForeignKey(RoadNode, on_delete=models.CASCADE, related_name="in_edges")
    travel_time = models.FloatField(validators=[MinValueValidator(0)], help_text="Minutes")
    distance_km = models.FloatField(default=0, validators=[MinValueValidator(0)])
    two_way = models.BooleanField(default=True)
    is_blocked = models.BooleanField(default=False, db_index=True)
    block_reason = models.CharField(max_length=255, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "road_edge"
        indexes = [models.Index(fields=["from_node", "to_node"])]

    def __str__(self):
        return f"{self.name or 'Road'} ({self.from_node_id}->{self.to_node_id})"


class GraphVersion(models.Model):
    """
    Single row; its token changes whenever the road graph changes, so every
    server process knows when to rebuild its in-memory graph. A random token
    (not a counter) is used so a rolled-back transaction can never make two
    different road networks look like the same version.
    """

    token = models.CharField(max_length=32, default="")

    class Meta:
        db_table = "graph_version"

    @classmethod
    def bump(cls):
        token = uuid.uuid4().hex
        updated = cls.objects.filter(pk=1).update(token=token)
        if not updated:
            cls.objects.create(pk=1, token=token)
        return token

    @classmethod
    def current(cls):
        return cls.objects.filter(pk=1).values_list("token", flat=True).first() or ""


# ---------------------------------------------------------------------------
# Fleet and resources
# ---------------------------------------------------------------------------


class Vehicle(models.Model):
    code = models.CharField(max_length=20, unique=True, blank=True)
    license_plate = models.CharField(max_length=30, unique=True)
    type = models.CharField(max_length=30, choices=VehicleType.choices, db_index=True)
    status = models.CharField(max_length=20, choices=VehicleStatus.choices,
                              default=VehicleStatus.AVAILABLE, db_index=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    driver = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True,
                               on_delete=models.SET_NULL, related_name="vehicles")
    crew_required = models.PositiveSmallIntegerField(default=2)
    fuel_level = models.PositiveSmallIntegerField(default=100, validators=[MaxValueValidator(100)])
    capabilities = models.JSONField(default=list, blank=True)
    station_name = models.CharField(max_length=120, blank=True)
    last_location_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "vehicle"
        ordering = ["id"]

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.code:
            self.code = f"VH-{self.id:03d}"
            super().save(update_fields=["code"])

    def __str__(self):
        return f"{self.code} {self.type} ({self.license_plate})"


class Resource(models.Model):
    name = models.CharField(max_length=160)
    category = models.CharField(max_length=20, choices=ResourceCategory.choices, db_index=True)
    quantity = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    unit = models.CharField(max_length=30, default="units")
    status = models.CharField(max_length=20, choices=ResourceStatus.choices, default=ResourceStatus.AVAILABLE)
    vehicle = models.ForeignKey(Vehicle, null=True, blank=True, on_delete=models.SET_NULL,
                                related_name="resources")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "resource"
        ordering = ["id"]

    @property
    def code(self):
        return f"RES-{self.id:03d}"

    def save(self, *args, **kwargs):
        if self.quantity <= 0:
            self.status = ResourceStatus.DEPLETED
        elif self.status == ResourceStatus.DEPLETED:
            self.status = ResourceStatus.AVAILABLE
        super().save(*args, **kwargs)


class VehicleLocationLog(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="location_logs")
    latitude = models.FloatField()
    longitude = models.FloatField()
    recorded_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = "vehicle_location_log"


# ---------------------------------------------------------------------------
# Emergencies, plans, assignments
# ---------------------------------------------------------------------------


class Emergency(models.Model):
    code = models.CharField(max_length=20, unique=True, blank=True)
    category = models.CharField(max_length=20, choices=EmergencyCategory.choices, db_index=True)
    status = models.CharField(max_length=20, choices=EmergencyStatus.choices,
                              default=EmergencyStatus.REPORTED, db_index=True)
    severity = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    urgency = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    people_affected = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    description = models.TextField(blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    location_label = models.CharField(max_length=255, blank=True)
    reported_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True,
                                    on_delete=models.SET_NULL, related_name="emergencies")
    priority_score = models.FloatField(default=0, db_index=True)
    vehicles_required = models.PositiveSmallIntegerField(default=1)
    allocation_reason = models.TextField(blank=True)
    # SELECTED / LOWER_PRIORITY / INSUFFICIENT_RESOURCES / UNREACHABLE / VEHICLE_CONFLICT / MANUAL
    allocation_code = models.CharField(max_length=30, blank=True, db_index=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "emergency"
        ordering = ["-created_at", "-id"]

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.code:
            self.code = f"EM-{self.created_at.year}-{self.id:04d}"
            super().save(update_fields=["code"])

    def __str__(self):
        return f"{self.code} {self.category} [{self.status}]"


class Plan(models.Model):
    class Reason(models.TextChoices):
        MANUAL = "MANUAL", "Manual run"
        NEW_EMERGENCY = "NEW_EMERGENCY", "New emergency"
        VEHICLE_FREE = "VEHICLE_FREE", "Vehicle became free"
        ROAD_BLOCKED = "ROAD_BLOCKED", "Road blocked/unblocked"
        MANUAL_ASSIGN = "MANUAL_ASSIGN", "Dispatcher manual assignment"

    reason = models.CharField(max_length=20, choices=Reason.choices, default=Reason.MANUAL)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
    summary = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = "plan"
        ordering = ["-id"]


class Assignment(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "ACTIVE", "Active"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"
        SUPERSEDED = "SUPERSEDED", "Superseded by a newer plan"

    plan = models.ForeignKey(Plan, null=True, blank=True, on_delete=models.SET_NULL, related_name="assignments")
    emergency = models.ForeignKey(Emergency, on_delete=models.CASCADE, related_name="assignments")
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="assignments")
    route_nodes = models.JSONField(default=list, blank=True)
    route_edges = models.JSONField(default=list, blank=True)
    route_coords = models.JSONField(default=list, blank=True)  # [[lat, lng], ...]
    eta_minutes = models.FloatField(null=True, blank=True)
    distance_km = models.FloatField(null=True, blank=True)
    route_unreachable = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE, db_index=True)
    notes = models.TextField(blank=True)
    assigned_at = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "assignment"
        ordering = ["-assigned_at", "-id"]
        indexes = [models.Index(fields=["vehicle", "status"]), models.Index(fields=["emergency", "status"])]


# ---------------------------------------------------------------------------
# Notifications and audit
# ---------------------------------------------------------------------------


class Notification(models.Model):
    TARGET_ALL = "all"

    title = models.CharField(max_length=200)
    message = models.TextField()
    target_role = models.CharField(max_length=20, default=TARGET_ALL, db_index=True)
    target_user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True,
                                    on_delete=models.CASCADE, related_name="notifications")
    emergency = models.ForeignKey(Emergency, null=True, blank=True, on_delete=models.SET_NULL)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = "notification"
        ordering = ["-created_at", "-id"]


class NotificationRead(models.Model):
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name="reads")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    read_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = "notification_read"
        constraints = [models.UniqueConstraint(fields=["notification", "user"], name="uniq_notification_read")]


class AuditLog(models.Model):
    event = models.CharField(max_length=60, db_index=True)
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = "audit_log"
        ordering = ["-created_at", "-id"]
