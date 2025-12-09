"""
Views for user authentication and management.
"""
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
 
from .serializers import (
    UserRegistrationSerializer,
    UserSerializer,
    UserUpdateSerializer,
    ChangePasswordSerializer,
    CustomTokenObtainPairSerializer
)

User = get_user_model()


class CustomTokenObtainPairView(TokenObtainPairView):
    """Custom login view that returns user data along with tokens."""
    serializer_class = CustomTokenObtainPairSerializer


class UserRegistrationView(generics.CreateAPIView):
    """
    API endpoint for user registration.
    
    POST /api/auth/register/
    Body: {
        "email": "user@example.com",
        "password": "securepassword",
        "password_confirm": "securepassword",
        "first_name": "John",
        "last_name": "Doe",
        "phone_number": "+1234567890",
        "company_name": "SuperMart Store",
        "address": "123 Main St"
    }
    """
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate tokens for the new user
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'user': UserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    API endpoint to retrieve and update user profile.
    
    GET /api/auth/profile/
    PUT/PATCH /api/auth/profile/
    """
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserUpdateSerializer
        return UserSerializer


class ChangePasswordView(APIView):
    """
    API endpoint for changing user password.
    
    POST /api/auth/change-password/
    Body: {
        "old_password": "currentpassword",
        "new_password": "newsecurepassword",
        "new_password_confirm": "newsecurepassword"
    }
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            user = request.user
            
            # Check old password
            if not user.check_password(serializer.validated_data['old_password']):
                return Response(
                    {'old_password': ['Wrong password.']},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Set new password
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            
            return Response(
                {'message': 'Password updated successfully'},
                status=status.HTTP_200_OK
            )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    """
    API endpoint for user logout (blacklist refresh token).
    
    POST /api/auth/logout/
    Body: {
        "refresh": "refresh_token_here"
    }
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if not refresh_token:
                return Response(
                    {'error': 'Refresh token is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            token = RefreshToken(refresh_token)
            token.blacklist()
            
            return Response(
                {'message': 'Logout successful'},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def user_stats(request):
    """
    Get user statistics.
    
    GET /api/auth/stats/
    """
    user = request.user
    
    # Import here to avoid circular imports
    from products.models import Product
    
    total_products = Product.objects.filter(created_by=user).count()
    low_stock = Product.objects.filter(
        created_by=user, 
        quantity__lte=10
    ).count()
    
    return Response({
        'total_products': total_products,
        'low_stock_products': low_stock,
        'user_since': user.created_at,
    })


class GoogleAuthView(APIView):
    """
    Google OAuth initiation endpoint.
    
    GET /api/auth/google/
    Redirects to Google OAuth consent screen.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        """
        Redirect to Google OAuth authorization URL.
        Note: This is a placeholder. Requires proper Google OAuth setup.
        """
        # Placeholder response - in production, this would redirect to Google OAuth
        return Response({
            'error': 'Google authentication not yet implemented',
            'message': 'Please use regular email/password authentication for now',
            'status': 'not_implemented'
        }, status=status.HTTP_501_NOT_IMPLEMENTED)


class GoogleAuthCallbackView(APIView):
    """
    Google OAuth callback endpoint.
    
    GET /api/auth/google/callback/
    Handles the OAuth callback from Google.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        """
        Handle Google OAuth callback.
        Note: This is a placeholder. Requires proper Google OAuth setup.
        """
        # Placeholder response - in production, this would process the OAuth callback
        return Response({
            'error': 'Google authentication callback not yet implemented',
            'message': 'Please use regular email/password authentication for now',
            'status': 'not_implemented'
        }, status=status.HTTP_501_NOT_IMPLEMENTED)
