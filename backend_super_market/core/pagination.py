"""
Custom Pagination Classes - Standardized pagination across the API.
Provides consistent response format and configuration.
"""
from rest_framework.pagination import PageNumberPagination, CursorPagination
from rest_framework.response import Response
from collections import OrderedDict


class StandardResultsPagination(PageNumberPagination):
    """
    Standard pagination with customizable page size.
    Provides comprehensive pagination metadata.
    """
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    
    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ('success', True),
            ('count', self.page.paginator.count),
            ('total_pages', self.page.paginator.num_pages),
            ('current_page', self.page.number),
            ('page_size', self.get_page_size(self.request)),
            ('next', self.get_next_link()),
            ('previous', self.get_previous_link()),
            ('results', data),
        ]))

    def get_paginated_response_schema(self, schema):
        return {
            'type': 'object',
            'properties': {
                'success': {'type': 'boolean'},
                'count': {'type': 'integer'},
                'total_pages': {'type': 'integer'},
                'current_page': {'type': 'integer'},
                'page_size': {'type': 'integer'},
                'next': {'type': 'string', 'nullable': True},
                'previous': {'type': 'string', 'nullable': True},
                'results': schema,
            },
        }


class LargeResultsPagination(StandardResultsPagination):
    """Pagination for large datasets (reports, analytics)."""
    page_size = 50
    max_page_size = 500


class SmallResultsPagination(StandardResultsPagination):
    """Pagination for small datasets (notifications, alerts)."""
    page_size = 10
    max_page_size = 50


class CursorResultsPagination(CursorPagination):
    """
    Cursor-based pagination for real-time data streams.
    More efficient for large datasets with frequent updates.
    """
    page_size = 20
    ordering = '-created_at'
    cursor_query_param = 'cursor'
    
    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ('success', True),
            ('next', self.get_next_link()),
            ('previous', self.get_previous_link()),
            ('results', data),
        ]))


class InfiniteScrollPagination(CursorPagination):
    """Pagination optimized for infinite scroll interfaces."""
    page_size = 15
    ordering = '-created_at'
    
    def get_paginated_response(self, data):
        return Response(OrderedDict([
            ('success', True),
            ('has_more', self.has_next),
            ('next_cursor', self.get_next_link()),
            ('results', data),
        ]))
