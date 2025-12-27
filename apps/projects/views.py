from django.shortcuts import get_object_or_404, render

from .models import Project


def project_list(request):
    projects = Project.objects.all()
    tech_filter = request.GET.get('tech')
    if tech_filter:
        projects = projects.filter(technologies__contains=tech_filter)

    all_technologies = set()
    for project in Project.objects.all():
        all_technologies.update(project.technologies)

    context = {
        'projects': projects,
        'technologies': sorted(all_technologies),
        'current_filter': tech_filter,
    }
    return render(request, 'projects/project_list.html', context)


def project_detail(request, slug):
    project = get_object_or_404(Project, slug=slug)
    return render(request, 'projects/project_detail.html', {'project': project})
