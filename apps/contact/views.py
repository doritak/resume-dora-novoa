from django.conf import settings
from django.contrib import messages
from django.core.mail import send_mail
from django.shortcuts import redirect, render

from .forms import ContactForm


def contact(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            contact_message = form.save()

            if settings.CONTACT_EMAIL:
                send_mail(
                    subject=f'Portfolio Contact: {contact_message.subject}',
                    message=f'From: {contact_message.name} <{contact_message.email}>\n\n{contact_message.message}',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[settings.CONTACT_EMAIL],
                    fail_silently=True,
                )

            messages.success(request, 'Thank you! Your message has been sent.')
            return redirect('contact:contact')
    else:
        form = ContactForm()

    return render(request, 'contact/contact.html', {'form': form})
