"""In-app notifications shown on the Citizen / Dispatcher / Driver / Admin screens."""


def notify(title, message, target_role="all", target_user=None, emergency=None):
    from dispatch.models import Notification

    return Notification.objects.create(
        title=title,
        message=message,
        target_role=target_role if target_user is None else "user",
        target_user=target_user,
        emergency=emergency,
    )
