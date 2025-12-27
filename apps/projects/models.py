from django.db import models
from django.urls import reverse


class Project(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    short_description = models.CharField(max_length=300)
    description = models.TextField()
    technologies = models.JSONField(default=list, help_text='List of technologies used')
    image = models.ImageField(upload_to='projects/', blank=True)
    github_url = models.URLField(blank=True)
    demo_url = models.URLField(blank=True)
    notebook_url = models.URLField(blank=True, help_text='Link to Colab/Kaggle notebook')
    featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-featured', '-created_at']

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        return reverse('projects:detail', kwargs={'slug': self.slug})
