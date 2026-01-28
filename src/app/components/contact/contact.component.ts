import { Component } from '@angular/core';

@Component({
  selector: 'app-contact',
  templateUrl: './contact.component.html'
})
export class ContactComponent {
  sectionTitle = 'Hablemos de tu proyecto';
  sectionSubtitle = 'Estamos listos para ayudarte a hacer realidad tu vision digital. Contactanos y comencemos a trabajar juntos.';

  contactInfo = {
    email: 'hola@studiolab.com',
    phone: '+34 900 123 456',
    address: 'Calle Innovacion 42, Madrid, Espana'
  };

  formData = {
    name: '',
    email: '',
    message: ''
  };

  onSubmit(): void {
    console.log('Form submitted:', this.formData);
  }
}
