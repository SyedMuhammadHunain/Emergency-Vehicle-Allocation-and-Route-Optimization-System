"""python manage.py prune_location_logs  - delete raw GPS logs older than the retention period (default 30 days)."""

from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone

from dispatch.models import VehicleLocationLog


class Command(BaseCommand):
    help = "Delete vehicle GPS location logs older than RESQ['LOCATION_LOG_RETENTION_DAYS']."

    def handle(self, *args, **opts):
        days = settings.RESQ["LOCATION_LOG_RETENTION_DAYS"]
        cutoff = timezone.now() - timedelta(days=days)
        deleted, _ = VehicleLocationLog.objects.filter(recorded_at__lt=cutoff).delete()
        self.stdout.write(self.style.SUCCESS(f"Deleted {deleted} location logs older than {days} days."))
