"""Audit trail (NFR Auditability): every assignment / plan event is stored with a timestamp."""

import json
import logging

logger = logging.getLogger("resq.audit")


def audit(event, actor=None, details=None):
    from dispatch.models import AuditLog

    actor = actor if (actor is not None and getattr(actor, "is_authenticated", False)) else None
    # Normalise enums/dates to plain JSON values.
    details = json.loads(json.dumps(details or {}, default=str))
    entry = AuditLog.objects.create(event=event, actor=actor, details=details)
    logger.info("%s actor=%s %s", event, getattr(actor, "id", None), details)
    return entry
