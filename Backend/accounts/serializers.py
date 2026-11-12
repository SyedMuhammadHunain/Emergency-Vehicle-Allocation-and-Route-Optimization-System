from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import Role, User


class UserSerializer(serializers.ModelSerializer):
    vehicle_id = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "code", "name", "email", "phone", "role", "is_active", "created_at", "vehicle_id"]
        read_only_fields = ["id", "code", "email", "role", "is_active", "created_at", "vehicle_id"]

    def get_vehicle_id(self, obj):
        if obj.role != Role.DRIVER:
            return None
        v = obj.vehicles.first()
        return v.id if v else None


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(trim_whitespace=False)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        existing = User.objects.filter(email=email).first()
        if existing and not existing.is_active and existing.check_password(attrs["password"]):
            raise serializers.ValidationError("This account has been deactivated by the administrator.")
        user = authenticate(self.context.get("request"), email=email, password=attrs["password"])
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        attrs["user"] = user
        return attrs


class RegisterSerializer(serializers.ModelSerializer):
    """Public sign-up: citizens only (matches the Flutter register screen)."""

    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ["name", "email", "phone", "password"]

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated):
        return User.objects.create_user(role=Role.CITIZEN, **validated)


class StaffCreateSerializer(RegisterSerializer):
    """Admin creates dispatcher or driver accounts."""

    role = serializers.ChoiceField(choices=[Role.DISPATCHER, Role.DRIVER])

    class Meta(RegisterSerializer.Meta):
        fields = RegisterSerializer.Meta.fields + ["role"]

    def create(self, validated):
        return User.objects.create_user(**validated)


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField()
    new_password = serializers.CharField(min_length=6)

    def validate_old_password(self, value):
        if not self.context["request"].user.check_password(value):
            raise serializers.ValidationError("Current password is incorrect.")
        return value
