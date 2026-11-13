"""Invalidate the cached road graph whenever roads change (admin site, shell, API)."""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .models import GraphVersion, RoadEdge, RoadNode


@receiver([post_save, post_delete], sender=RoadEdge)
@receiver([post_save, post_delete], sender=RoadNode)
def _road_changed(sender, **kwargs):
    if kwargs.get("raw"):
        return
    GraphVersion.bump()
