from django.conf import settings
from django.shortcuts import render

from apps.projects.models import Project


def home(request):
    featured_projects = Project.objects.filter(featured=True)[:3]
    context = {
        'site_name': settings.SITE_NAME,
        'site_tagline': settings.SITE_TAGLINE,
        'featured_projects': featured_projects,
    }
    return render(request, 'core/home.html', context)


def about(request):
    return render(request, 'core/about.html')
