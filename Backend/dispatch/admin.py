from django.contrib import admin

from . import models


@admin.register(models.Emergency)
class EmergencyAdmin(admin.ModelAdmin):
    list_display = ["code", "category", "status", "severity", "urgency", "people_affected", "priority_score", "created_at"]
    list_filter = ["status", "category"]
    search_fields = ["code", "description", "location_label"]


@admin.register(models.Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ["code", "license_plate", "type", "status", "driver", "fuel_level", "crew_required"]
    list_filter = ["type", "status"]


@admin.register(models.Resource)
class ResourceAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "category", "quantity", "unit", "status", "vehicle"]
    list_filter = ["category", "status"]


@admin.register(models.RoadEdge)
class RoadEdgeAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "from_node", "to_node", "travel_time", "distance_km", "is_blocked"]
    list_filter = ["is_blocked"]
    search_fields = ["name"]
    raw_id_fields = ["from_node", "to_node"]


@admin.register(models.Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ["id", "plan", "emergency", "vehicle", "status", "eta_minutes", "assigned_at"]
    list_filter = ["status"]


@admin.register(models.Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ["id", "reason", "created_by", "created_at"]


@admin.register(models.AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ["id", "event", "actor", "created_at"]
    list_filter = ["event"]


admin.site.register(models.RoadNode)
admin.site.register(models.Notification)
admin.site.site_header = "ResQ Administration"
