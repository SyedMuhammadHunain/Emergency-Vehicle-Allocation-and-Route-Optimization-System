from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter(trailing_slash=True)
router.register("emergencies", views.EmergencyViewSet, basename="emergency")
router.register("vehicles", views.VehicleViewSet, basename="vehicle")
router.register("resources", views.ResourceViewSet, basename="resource")
router.register("roads/nodes", views.RoadNodeViewSet, basename="road-node")
router.register("roads", views.RoadEdgeViewSet, basename="road")
router.register("assignments", views.AssignmentViewSet, basename="assignment")
router.register("audit-logs", views.AuditLogViewSet, basename="audit-log")

urlpatterns = [
    path("health/", views.health),
    path("map/", views.map_data),
    path("allocate/", views.AllocateView.as_view()),
    path("plan/current/", views.plan_current),
    path("plan/recalculate/", views.plan_recalculate),
    path("plan/history/", views.plan_history),
    path("route/", views.route_view),
    path("driver/mission/", views.driver_mission),
    path("driver/history/", views.driver_history),
    path("notifications/", views.notifications_list),
    path("notifications/read-all/", views.notifications_read_all),
    path("notifications/<int:pk>/read/", views.notification_read),
    path("reports/summary/", views.reports_summary),
] + router.urls
