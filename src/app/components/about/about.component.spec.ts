import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AboutComponent } from './about.component';

describe('AboutComponent', () => {
  let component: AboutComponent;
  let fixture: ComponentFixture<AboutComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AboutComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(AboutComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have section title', () => {
    expect(component.sectionTitle).toBe('Sobre Nosotros');
  });

  it('should have description', () => {
    expect(component.description).toBeTruthy();
    expect(component.description.length).toBeGreaterThan(0);
  });

  it('should have secondary text', () => {
    expect(component.secondaryText).toBeTruthy();
    expect(component.secondaryText.length).toBeGreaterThan(0);
  });

  it('should have 4 stats', () => {
    expect(component.stats.length).toBe(4);
  });

  it('should have stats with required properties', () => {
    component.stats.forEach(stat => {
      expect(stat.value).toBeTruthy();
      expect(stat.label).toBeTruthy();
    });
  });

  it('should render section title in template', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h2')?.textContent).toContain(component.sectionTitle);
  });

  it('should render all stat cards', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    const stats = compiled.querySelectorAll('.grid.grid-cols-2 > div');
    expect(stats.length).toBe(4);
  });

  it('should display years of experience stat', () => {
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('8+');
    expect(compiled.textContent).toContain('Anos de experiencia');
  });
});
