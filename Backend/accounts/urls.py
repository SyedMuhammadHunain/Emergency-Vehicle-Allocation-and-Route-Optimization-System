from django.urls import path

from . import views

auth_urlpatterns = [
    path("login/", views.LoginView.as_view()),
    path("register/", views.RegisterView.as_view()),
    path("logout/", views.LogoutView.as_view()),
    path("me/", views.MeView.as_view()),
    path("change-password/", views.ChangePasswordView.as_view()),
    path("forgot-password/", views.forgot_password),
]

user_urlpatterns = [
    path("", views.UserListCreateView.as_view()),
    path("counts/", views.user_counts),
    path("<int:pk>/", views.UserDetailView.as_view()),
    path("<int:pk>/toggle-active/", views.toggle_user_active),
]
