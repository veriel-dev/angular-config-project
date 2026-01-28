import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { ContactComponent } from './contact.component';

describe('ContactComponent', () => {
  let component: ContactComponent;
  let fixture: ComponentFixture<ContactComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ContactComponent],
      imports: [FormsModule]
    }).compileComponents();

    fixture = TestBed.createComponent(ContactComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have section title', () => {
    expect(component.sectionTitle).toBe('Hablemos de tu proyecto');
  });

  it('should have section subtitle', () => {
    expect(component.sectionSubtitle).toBeTruthy();
    expect(component.sectionSubtitle.length).toBeGreaterThan(0);
  });

  it('should have contact info with email', () => {
    expect(component.contactInfo.email).toBe('hola@studiolab.com');
  });

  it('should have contact info with phone', () => {
    expect(component.contactInfo.phone).toBe('+34 900 123 456');
  });

  it('should have contact info with address', () => {
    expect(component.contactInfo.address).toBeTruthy();
  });

  it('should have empty form data initially', () => {
    expect(component.formData.name).toBe('');
    expect(component.formData.email).toBe('');
    expect(component.formData.message).toBe('');
  });

  it('should render section title in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h2')?.textContent).toContain(component.sectionTitle);
  });

  it('should render contact form', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('form')).toBeTruthy();
  });

  it('should render form inputs', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('input[name="name"]')).toBeTruthy();
    expect(compiled.querySelector('input[name="email"]')).toBeTruthy();
    expect(compiled.querySelector('textarea[name="message"]')).toBeTruthy();
  });

  it('should render submit button', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const button = compiled.querySelector('button[type="submit"]');
    expect(button).toBeTruthy();
    expect(button?.textContent).toContain('Enviar mensaje');
  });

  it('should call onSubmit when form is submitted', () => {
    spyOn(component, 'onSubmit');
    const form = fixture.nativeElement.querySelector('form');
    form.dispatchEvent(new Event('submit'));
    expect(component.onSubmit).toHaveBeenCalled();
  });

  it('should execute onSubmit and log form data', () => {
    spyOn(console, 'log');
    component.formData = {
      name: 'Test User',
      email: 'test@example.com',
      message: 'Test message'
    };
    component.onSubmit();
    expect(console.log).toHaveBeenCalledWith('Form submitted:', component.formData);
  });
});
