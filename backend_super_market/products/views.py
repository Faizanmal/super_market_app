"""
Views for product, category, and supplier management.
"""
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta
 
from .models import Category, Supplier, Product, StockMovement
from .serializers import (
    CategorySerializer,
    SupplierSerializer,
    ProductListSerializer,
    ProductDetailSerializer,
    ProductCreateUpdateSerializer,
    StockMovementSerializer,
    BarcodeSearchSerializer,
)
from .filters import ProductFilter


class CategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product categories.
    
    list: Get all categories for current user
    create: Create a new category
    retrieve: Get category details
    update: Update category
    destroy: Delete category
    """
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_queryset(self):
        """Return categories for current user only."""
        return Category.objects.filter(created_by=self.request.user)


class SupplierViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing suppliers.
    
    list: Get all suppliers for current user
    create: Create a new supplier
    retrieve: Get supplier details
    update: Update supplier
    destroy: Delete supplier
    """
    serializer_class = SupplierSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'contact_person', 'email', 'phone']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_queryset(self):
        """Return suppliers for current user only."""
        return Supplier.objects.filter(created_by=self.request.user)


class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing products.
    
    list: Get all products with filtering and search
    create: Create a new product
    retrieve: Get product details
    update: Update product
    destroy: Delete product (soft delete)
    
    Custom actions:
    - expiring_soon: Get products expiring within 7 days
    - expired: Get expired products
    - low_stock: Get products with low stock
    - search_barcode: Search product by barcode
    """
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ProductFilter
    search_fields = ['name', 'barcode', 'sku', 'description']
    ordering_fields = ['name', 'expiry_date', 'quantity', 'created_at', 'selling_price']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Return products for current user only."""
        return Product.objects.filter(
            created_by=self.request.user,
            is_active=True
        ).select_related('category', 'supplier')
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'list':
            return ProductListSerializer
        elif self.action == 'retrieve':
            return ProductDetailSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ProductCreateUpdateSerializer
        return ProductDetailSerializer
    
    def destroy(self, request, *args, **kwargs):
        """Soft delete product."""
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response(
            {'message': 'Product deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Get products expiring within 7 days."""
        today = timezone.now().date()
        seven_days_later = today + timedelta(days=7)
        
        products = self.get_queryset().filter(
            expiry_date__gte=today,
            expiry_date__lte=seven_days_later
        ).order_by('expiry_date')
        
        serializer = ProductListSerializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expired(self, request):
        """Get expired products."""
        today = timezone.now().date()
        
        products = self.get_queryset().filter(
            expiry_date__lt=today
        ).order_by('expiry_date')
        
        serializer = ProductListSerializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get products with low stock."""
        from django.db.models import F
        
        products = self.get_queryset().filter(
            quantity__lte=F('min_stock_level')
        ).order_by('quantity')
        
        serializer = ProductListSerializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def search_barcode(self, request):
        """Search product by barcode."""
        serializer = BarcodeSearchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        barcode = serializer.validated_data['barcode']
        
        try:
            product = Product.objects.get(
                barcode=barcode,
                created_by=request.user,
                is_active=True
            )
            return Response(ProductDetailSerializer(product).data)
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found', 'barcode': barcode},
                status=status.HTTP_404_NOT_FOUND
            )


class StockMovementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing stock movements.
    
    list: Get all stock movements
    create: Create a new stock movement
    retrieve: Get movement details
    """
    serializer_class = StockMovementSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'movement_type']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Return stock movements for current user's products only."""
        return StockMovement.objects.filter(
            created_by=self.request.user
        ).select_related('product')
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent stock movements (last 30 days)."""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        movements = self.get_queryset().filter(
            created_at__gte=thirty_days_ago
        )[:50]
        
        serializer = self.get_serializer(movements, many=True)
        return Response(serializer.data)
