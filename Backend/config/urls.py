from rest_framework.permissions import AllowAny
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from django.contrib import admin
from django.urls import include, path

from accounts.urls import auth_urlpatterns, user_urlpatterns

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include(auth_urlpatterns)),
    path("api/users/", include(user_urlpatterns)),
    path("api/", include("dispatch.urls")),
    path("api/schema/", SpectacularAPIView.as_view(permission_classes=[AllowAny]), name="schema"),
path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema", permission_classes=[AllowAny]), name="docs"),
]
