import React, { useState, useEffect } from 'react';
import QRCode from 'qrcode.react';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs, query, orderBy, updateDoc, doc, deleteDoc } from 'firebase/firestore';
import { getAuth, signInAnonymously } from 'firebase/auth';

// Firebase configuration - using your existing Firebase project
const firebaseConfig = {
  apiKey: "AIzaSyD9h9Y_1_QmUHpJHK-66dtvUG6l5eUIa98",
  authDomain: "patient-qr-registration.firebaseapp.com",
  projectId: "patient-qr-registration",
  storageBucket: "patient-qr-registration.firebasestorage.app",
  messagingSenderId: "343467579186",
  appId: "1:343467579186:web:c8af7c7113f094c897292b",
  measurementId: "G-0FWB6SCXSJ"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// Ensure anonymous user is signed in
signInAnonymously(auth)
  .catch((error) => {
    console.error("Anonymous authentication failed:", error);
  });

function App() {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    mobileNumber: '',
    symptoms: '',
    visitType: 'Consultation',
    hospitalId: '',
    hospitalName: ''
  });
  
  const [clinicData, setClinicData] = useState({
    name: '',
    address: '',
    phone: '',
    department: ''
  });
  
  const [mrData, setMrData] = useState({
    fullName: '',
    company: '',
    email: '',
    mobileNumber: '',
    specialty: '',
    visitPurpose: 'Product Presentation',
    preferredDate: '',
    preferredTime: '',
    hospitalId: '',
    hospitalName: ''
  });
  
  const [registrationStep, setRegistrationStep] = useState('main'); // 'main', 'form', 'mr-form'
  const [qrValue, setQrValue] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [registrations, setRegistrations] = useState([]);
  const [mrRegistrations, setMrRegistrations] = useState([]);
  const [clinics, setClinics] = useState([]);
  const [selectedClinic, setSelectedClinic] = useState('');
  const [showClinicForm, setShowClinicForm] = useState(false);
  const [generatedQRs, setGeneratedQRs] = useState([]);
  const [activeTab, setActiveTab] = useState('generate'); // 'generate', 'patients', 'mrs', 'clinics'
  const [filteredRegistrations, setFilteredRegistrations] = useState([]);
  const [filteredMRs, setFilteredMRs] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [mrStatusFilter, setMrStatusFilter] = useState('all');
  const [showQRModal, setShowQRModal] = useState(false);
  const [viewingQR, setViewingQR] = useState(null);
  const [editingClinic, setEditingClinic] = useState(null);
  const [showEditClinicModal, setShowEditClinicModal] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  
  // Ad Management State
  const [ads, setAds] = useState([]);
  const [showAdForm, setShowAdForm] = useState(false);
  const [editingAd, setEditingAd] = useState(null);
  const [adFormData, setAdFormData] = useState({
    title: '',
    imageUrl: '',
    targetUrl: '',
    priority: 0,
    clinicId: '',
    isActive: true
  });
  
  // Doctor Management State
  const [doctors, setDoctors] = useState([]);
  const [selectedDoctorClinic, setSelectedDoctorClinic] = useState('');

  // Download QR code as PNG
  const handleDownloadQR = (qr) => {
    downloadQRAsPNG(qr);
  };

  // Delete QR code
  const handleDeleteQR = async (qrId) => {
    if (window.confirm('Are you sure you want to delete this QR code?')) {
      try {
        await deleteDoc(doc(db, 'generated_qrs', qrId));
        setGeneratedQRs(prev => prev.filter(qr => qr.id !== qrId));
        setMessage({ type: 'success', text: '✅ QR code deleted successfully!' });
      } catch (error) {
        console.error('Error deleting QR code:', error);
        setMessage({ type: 'error', text: 'Failed to delete QR code' });
      }
    }
  };

  // Edit clinic
  const handleEditClinic = (clinic) => {
    setEditingClinic({ ...clinic });
    setShowEditClinicModal(true);
  };

  // Update clinic
  const handleUpdateClinic = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await updateDoc(doc(db, 'clinics', editingClinic.id), {
        name: editingClinic.name,
        address: editingClinic.address,
        phone: editingClinic.phone,
        department: editingClinic.department
      });
      
      setClinics(prev => prev.map(c => c.id === editingClinic.id ? editingClinic : c));
      setShowEditClinicModal(false);
      setEditingClinic(null);
      setMessage({ type: 'success', text: '✅ Clinic updated successfully!' });
    } catch (error) {
      console.error('Error updating clinic:', error);
      setMessage({ type: 'error', text: 'Failed to update clinic' });
    } finally {
      setLoading(false);
    }
  };

  // Generate QR code value for specific clinic (Patient Registration)
  const generateQRCode = async () => {
    if (!selectedClinic) return;
    
    // Use network IP address for mobile scanning
    const networkIP = '192.168.0.108';
    const port = window.location.port || '3000';
    const baseUrl = `http://${networkIP}:${port}`;
    
    const uniqueId = Date.now().toString();
    const clinic = clinics.find(c => c.id === selectedClinic);
    const registrationUrl = `${baseUrl}/register?clinic=${selectedClinic}&id=${uniqueId}&hospital=${encodeURIComponent(clinic?.name || '')}`;
    
    console.log('Generated QR URL:', registrationUrl); // Debug log
    setQrValue(registrationUrl);
    setRegistrationStep('qr');
    
    // Save generated QR to Firebase
    if (clinic) {
      const newQR = {
        id: uniqueId,
        clinicId: selectedClinic,
        clinicName: clinic.name,
        qrUrl: registrationUrl,
        type: 'patient',
        createdAt: new Date()
      };
      
      try {
        await addDoc(collection(db, 'generated_qrs'), newQR);
        
        // Also update local state
        setGeneratedQRs(prev => [...prev, newQR]);
        
        setMessage({ type: 'success', text: 'Patient QR code generated and saved!' });
      } catch (error) {
        console.error('Error saving QR code:', error);
        setMessage({ type: 'error', text: 'Error saving QR code: ' + error.message });
      }
    }
  };

  // Generate MR Appointment QR code
  const generateMRQRCode = async () => {
    if (!selectedClinic) return;
    
    // Use network IP address for mobile scanning
    const networkIP = '192.168.0.108';
    const port = window.location.port || '3000';
    const baseUrl = `http://${networkIP}:${port}`;
    
    const uniqueId = `mr_${Date.now()}`;
    const clinic = clinics.find(c => c.id === selectedClinic);
    const mrUrl = `${baseUrl}/mr-register?clinic=${selectedClinic}&id=${uniqueId}&hospital=${encodeURIComponent(clinic?.name || '')}`;
    
    console.log('Generated MR QR URL:', mrUrl); // Debug log
    setQrValue(mrUrl);
    
    // Save generated MR QR to Firebase
    if (clinic) {
      const newMRQR = {
        id: uniqueId,
        clinicId: selectedClinic,
        clinicName: clinic.name,
        qrUrl: mrUrl,
        type: 'mr',
        createdAt: new Date()
      };
      
      try {
        await addDoc(collection(db, 'generated_qrs'), newMRQR);
        
        // Also update local state
        setGeneratedQRs(prev => [...prev, newMRQR]);
        
        setMessage({ type: 'success', text: 'MR QR code generated and saved!' });
      } catch (error) {
        console.error('Error saving MR QR code:', error);
        setMessage({ type: 'error', text: 'Error saving MR QR code: ' + error.message });
      }
    }
  };

  // Handle clinic form input changes
  const handleClinicInputChange = (e) => {
    const { name, value } = e.target;
    setClinicData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // Handle clinic creation
  const handleCreateClinic = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ type: '', text: '' });
    
    try {
      const clinicToAdd = {
        name: clinicData.name,
        address: clinicData.address,
        phone: clinicData.phone,
        department: clinicData.department || 'General',
        createdAt: new Date()
      };

      const docRef = await addDoc(collection(db, 'clinics'), clinicToAdd);
      
      const newClinic = {
        id: docRef.id,
        ...clinicToAdd
      };
      
      setClinics(prev => [...prev, newClinic]);
      setSelectedClinic(docRef.id);
      
      setMessage({ type: 'success', text: 'Clinic created successfully!' });
      
      // Reset form
      setClinicData({
        name: '',
        address: '',
        phone: '',
        department: ''
      });
      
      setShowClinicForm(false);
      
      // Auto-generate QR for the new clinic
      setTimeout(() => {
        generateQRCode();
      }, 500);
      
    } catch (error) {
      console.error('Error adding clinic:', error);
      setMessage({ type: 'error', text: 'Error creating clinic: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  // Handle form input changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ type: '', text: '' });
    
    try {
      // Add registration to Firestore with clinic association
      const registrationData = {
        firstName: formData.firstName,
        lastName: formData.lastName,
        fullName: `${formData.firstName} ${formData.lastName}`,
        email: formData.email,
        mobileNumber: formData.mobileNumber,
        symptoms: formData.symptoms,
        visitType: formData.visitType,
        hospitalId: selectedClinic,
        hospitalName: clinics.find(c => c.id === selectedClinic)?.name || 'Unknown Clinic',
        status: 'registered',
        createdAt: new Date()
      };

      await addDoc(collection(db, 'qr_registrations'), registrationData);
      
      setMessage({ type: 'success', text: 'Registration successful! Data saved to Firebase.' });
      
      // Reset form
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        mobileNumber: '',
        symptoms: '',
        visitType: 'Consultation',
        hospitalId: '',
        hospitalName: ''
      });
      
      // Fetch updated registrations
      fetchRegistrations();
    } catch (error) {
      console.error('Error adding document:', error);
      setMessage({ type: 'error', text: 'Error saving data: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  // Fetch registrations from Firestore
  const fetchRegistrations = async () => {
    try {
      const q = query(collection(db, 'qr_registrations'), orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);
      const registrationList = [];
      querySnapshot.forEach((doc) => {
        registrationList.push({ id: doc.id, ...doc.data() });
      });
      setRegistrations(registrationList);
    } catch (error) {
      console.error('Error fetching registrations:', error);
    }
  };

  // Fetch clinics from Firestore
  const fetchClinics = async () => {
    try {
      const q = query(collection(db, 'clinics'), orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);
      const clinicList = [];
      querySnapshot.forEach((doc) => {
        clinicList.push({ id: doc.id, ...doc.data() });
      });
      setClinics(clinicList);
      if (clinicList.length > 0 && !selectedClinic) {
        setSelectedClinic(clinicList[0].id);
      }
    } catch (error) {
      console.error('Error fetching clinics:', error);
    }
  };

  // ========== AD MANAGEMENT FUNCTIONS ==========
  
  // Fetch ads from Firestore
  const fetchAds = async () => {
    try {
      const q = query(collection(db, 'ads'), orderBy('priority', 'desc'));
      const querySnapshot = await getDocs(q);
      const adList = [];
      querySnapshot.forEach((doc) => {
        adList.push({ id: doc.id, ...doc.data() });
      });
      setAds(adList);
    } catch (error) {
      console.error('Error fetching ads:', error);
    }
  };

  // Fetch doctors from backend API (users with role='doctor')
  const fetchDoctors = async () => {
    try {
      // First get current user token using form data
      const formData = new FormData();
      formData.append('username', 'yakshith.s.y123@gmail.com');
      formData.append('password', 'Yakshith123');
      
      const loginResponse = await fetch('http://localhost:8000/api/auth/login', {
        method: 'POST',
        body: formData
      });
      
      if (!loginResponse.ok) {
        const errorData = await loginResponse.json();
        throw new Error(errorData.detail || 'Login failed');
      }
      
      const loginData = await loginResponse.json();
      const token = loginData.access_token;
      
      // Now fetch all users with doctor role from the list-all endpoint
      const response = await fetch('http://localhost:8000/api/doctors/list-all', {
        headers: {
          'Authorization': `Bearer ${token}`,
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        setDoctors(data);
        console.log(`Loaded ${data.length} doctors with clinics:`, data.map(d => ({ name: d.name, clinics: d.clinic_names })));
      } else {
        console.error('Failed to fetch doctors:', response.status);
        setMessage({ type: 'error', text: `Failed to fetch doctors (${response.status})` });
      }
    } catch (error) {
      console.error('Error fetching doctors:', error);
      setMessage({ type: 'error', text: `Error: ${error.message}` });
    }
  };

  // Update doctor's selected clinics
  const handleUpdateDoctorClinics = async (doctorId, newClinicIds) => {
    setLoading(true);
    try {
      const response = await fetch(`http://localhost:8000/api/doctors/${doctorId}/clinics`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          associated_clinic_ids: newClinicIds
        })
      });
      
      if (response.ok) {
        setMessage({ type: 'success', text: '✅ Doctor clinics updated successfully!' });
        fetchDoctors(); // Refresh list
      } else {
        setMessage({ type: 'error', text: 'Failed to update doctor clinics' });
      }
    } catch (error) {
      console.error('Error updating doctor clinics:', error);
      setMessage({ type: 'error', text: 'Error updating clinics' });
    } finally {
      setLoading(false);
    }
  };

  // Handle ad form input changes
  const handleAdInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setAdFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  // Create or update ad
  const handleSaveAd = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ type: '', text: '' });
    
    try {
      const adData = {
        title: adFormData.title,
        imageUrl: adFormData.imageUrl,
        targetUrl: adFormData.targetUrl || '',
        priority: parseInt(adFormData.priority) || 0,
        clinicId: adFormData.clinicId || null,
        isActive: adFormData.isActive,
        adType: 'banner',
        createdAt: new Date()
      };

      if (editingAd) {
        // Update existing ad
        await updateDoc(doc(db, 'ads', editingAd.id), adData);
        setMessage({ type: 'success', text: '✅ Ad updated successfully! Will appear on doctor dashboard.' });
      } else {
        // Create new ad
        await addDoc(collection(db, 'ads'), adData);
        setMessage({ type: 'success', text: '✅ Ad created successfully! Will appear on doctor dashboard.' });
      }
      
      // Reset form and refresh list
      setAdFormData({
        title: '',
        imageUrl: '',
        targetUrl: '',
        priority: 0,
        clinicId: '',
        isActive: true
      });
      setShowAdForm(false);
      setEditingAd(null);
      fetchAds();
    } catch (error) {
      console.error('Error saving ad:', error);
      setMessage({ type: 'error', text: 'Failed to save ad: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  // Delete ad
  const handleDeleteAd = async (adId) => {
    if (window.confirm('Are you sure you want to delete this ad? It will be removed from the doctor dashboard.')) {
      try {
        await deleteDoc(doc(db, 'ads', adId));
        fetchAds();
        setMessage({ type: 'success', text: '✅ Ad deleted successfully!' });
      } catch (error) {
        console.error('Error deleting ad:', error);
        setMessage({ type: 'error', text: 'Failed to delete ad: ' + error.message });
      }
    }
  };

  // Edit ad
  const handleEditAd = (ad) => {
    setEditingAd(ad);
    setAdFormData({
      title: ad.title,
      imageUrl: ad.imageUrl,
      targetUrl: ad.targetUrl || '',
      priority: ad.priority || 0,
      clinicId: ad.clinicId || '',
      isActive: ad.isActive
    });
    setShowAdForm(true);
  };

  // Handle MR form input changes
  const handleMRInputChange = (e) => {
    const { name, value } = e.target;
    setMrData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // Handle MR registration submission
  const handleMRSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ type: '', text: '' });
    
    try {
      const registrationData = {
        ...mrData,
        status: 'pending',
        createdAt: new Date()
      };

      await addDoc(collection(db, 'mr_registrations'), registrationData);
      
      setMessage({ type: 'success', text: 'Appointment request submitted successfully!' });
      
      // Reset form
      setMrData({
        fullName: '',
        company: '',
        email: '',
        mobileNumber: '',
        specialty: '',
        visitPurpose: 'Product Presentation',
        preferredDate: '',
        preferredTime: '',
        hospitalId: '',
        hospitalName: ''
      });
      
      // Fetch updated registrations
      fetchMRRegistrations();
    } catch (error) {
      console.error('Error adding MR registration:', error);
      setMessage({ type: 'error', text: 'Error saving data: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  // Fetch MR registrations from Firestore
  const fetchMRRegistrations = async () => {
    try {
      const q = query(collection(db, 'mr_registrations'), orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);
      const mrList = [];
      querySnapshot.forEach((doc) => {
        mrList.push({ id: doc.id, ...doc.data() });
      });
      setMrRegistrations(mrList);
    } catch (error) {
      console.error('Error fetching MR registrations:', error);
    }
  };

  // Update MR status
  const updateMRStatus = async (mrId, newStatus) => {
    try {
      const mrRef = doc(db, 'mr_registrations', mrId);
      await updateDoc(mrRef, { status: newStatus });
      
      setMrRegistrations(prev => prev.map(mr => 
        mr.id === mrId ? { ...mr, status: newStatus } : mr
      ));
      
      setMessage({ type: 'success', text: `MR status updated to ${newStatus}` });
    } catch (error) {
      console.error('Error updating MR status:', error);
      setMessage({ type: 'error', text: 'Failed to update MR status' });
    }
  };

  // Delete MR registration
  const deleteMRRegistration = async (mrId) => {
    if (!window.confirm('Are you sure you want to delete this MR registration?')) return;
    
    try {
      await deleteDoc(doc(db, 'mr_registrations', mrId));
      setMrRegistrations(prev => prev.filter(mr => mr.id !== mrId));
      setMessage({ type: 'success', text: 'MR registration deleted successfully' });
    } catch (error) {
      console.error('Error deleting MR registration:', error);
      setMessage({ type: 'error', text: 'Failed to delete MR registration' });
    }
  };

  // Fetch generated QR codes from Firestore
  const fetchGeneratedQRs = async () => {
    try {
      const q = query(collection(db, 'generated_qrs'), orderBy('createdAt', 'desc'));
      const querySnapshot = await getDocs(q);
      const qrList = [];
      querySnapshot.forEach((doc) => {
        qrList.push({ id: doc.id, ...doc.data() });
      });
      setGeneratedQRs(qrList);
    } catch (error) {
      console.error('Error fetching generated QR codes:', error);
    }
  };

  // Check if this is a registration page
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const isRegisterPage = urlParams.get('id');
    const clinicId = urlParams.get('clinic');
    const hospitalName = urlParams.get('hospital');
    
    if (isRegisterPage) {
      setRegistrationStep('form');
      if (clinicId) {
        setSelectedClinic(clinicId);
        setFormData(prev => ({
          ...prev,
          hospitalId: clinicId,
          hospitalName: decodeURIComponent(hospitalName || '')
        }));
      }
    } else {
      // On initial load, fetch clinics
      fetchClinics();
    }
  }, []);

  // Initial data fetch
  useEffect(() => {
    setIsLoading(true);
    fetchClinics().then(() => {
      // Load other data lazily to improve initial load time
      setTimeout(() => {
        Promise.all([
          fetchRegistrations(),
          fetchMRRegistrations(),
          fetchGeneratedQRs(),
          fetchAds(),
          fetchDoctors()
        ]).then(() => {
          setIsLoading(false);
        });
      }, 300);
    });
    
    // Auto-refresh doctors every 10 seconds to show new registrations
    const intervalId = setInterval(fetchDoctors, 10000);
    
    return () => clearInterval(intervalId);
  }, []);

  // Filter registrations based on search and status
  useEffect(() => {
    let filtered = [...registrations];
    
    if (searchTerm) {
      filtered = filtered.filter(reg => 
        reg.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        reg.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        reg.mobileNumber.includes(searchTerm)
      );
    }
    
    if (statusFilter !== 'all') {
      filtered = filtered.filter(reg => reg.status === statusFilter);
    }
    
    setFilteredRegistrations(filtered);
  }, [searchTerm, statusFilter, registrations]);

  // Filter MRs based on search and status
  useEffect(() => {
    let filtered = [...mrRegistrations];
    
    if (searchTerm) {
      filtered = filtered.filter(mr => 
        mr.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        mr.company.toLowerCase().includes(searchTerm.toLowerCase()) ||
        mr.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        mr.mobileNumber.includes(searchTerm)
      );
    }
    
    if (mrStatusFilter !== 'all') {
      filtered = filtered.filter(mr => mr.status === mrStatusFilter);
    }
    
    setFilteredMRs(filtered);
  }, [searchTerm, mrStatusFilter, mrRegistrations]);

  // Update patient status
  const updatePatientStatus = async (registrationId, newStatus) => {
    try {
      const registrationRef = doc(db, 'qr_registrations', registrationId);
      await updateDoc(registrationRef, { status: newStatus });
      
      // Update local state
      setRegistrations(prev => prev.map(reg => 
        reg.id === registrationId ? { ...reg, status: newStatus } : reg
      ));
      
      setMessage({ type: 'success', text: `Status updated to ${newStatus}` });
    } catch (error) {
      console.error('Error updating status:', error);
      setMessage({ type: 'error', text: 'Failed to update status' });
    }
  };

  // Delete registration
  const deleteRegistration = async (registrationId) => {
    if (!window.confirm('Are you sure you want to delete this registration?')) return;
    
    try {
      await deleteDoc(doc(db, 'qr_registrations', registrationId));
      setRegistrations(prev => prev.filter(reg => reg.id !== registrationId));
      setMessage({ type: 'success', text: 'Registration deleted successfully' });
    } catch (error) {
      console.error('Error deleting registration:', error);
      setMessage({ type: 'error', text: 'Failed to delete registration' });
    }
  };

  // Export registrations to CSV
  const exportToCSV = () => {
    const headers = ['Name', 'Email', 'Phone', 'Hospital', 'Visit Type', 'Symptoms', 'Status', 'Date'];
    const csvData = registrations.map(reg => [
      reg.fullName,
      reg.email,
      reg.mobileNumber,
      reg.hospitalName,
      reg.visitType,
      reg.symptoms,
      reg.status,
      new Date(reg.createdAt.seconds * 1000).toLocaleString()
    ]);
    
    const csvContent = [
      headers.join(','),
      ...csvData.map(row => row.map(cell => `"${cell}"`).join(','))
    ].join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `registrations_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
  };

  // Handle view QR code in modal
  const handleViewQR = (qr) => {
    setViewingQR(qr);
    setShowQRModal(true);
  };

  // Alternative simple download method
  const downloadQRAsPNG = async (qr) => {
    try {
      // Create a canvas element
      const canvas = document.createElement('canvas');
      const size = 512;
      canvas.width = size;
      canvas.height = size;
      
      const ctx = canvas.getContext('2d');
      
      // Draw white background
      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, size, size);
      
      // Draw QR code using qrcode library
      const QRCode = require('qrcode');
      await QRCode.toCanvas(canvas, qr.qrUrl, { 
        width: size,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      
      // Convert to blob and download
      canvas.toBlob((blob) => {
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.download = `${qr.clinicName.replace(/\s+/g, '_')}_${qr.type.toUpperCase()}_QR.png`;
        link.href = url;
        link.click();
        URL.revokeObjectURL(url);
        
        setMessage({ type: 'success', text: 'QR code downloaded successfully!' });
      }, 'image/png');
    } catch (error) {
      console.error('Error downloading QR code:', error);
      setMessage({ type: 'error', text: 'Failed to download QR code' });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {isLoading ? (
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <h2 className="text-2xl font-bold text-gray-800 mb-2">Loading MediFlow Pro...</h2>
            <p className="text-gray-600">Please wait while we fetch your data</p>
          </div>
        </div>
      ) : (
        <>
          <header className="bg-white shadow-lg border-b-2 border-blue-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-800">Medical QR Admin Panel</h1>
            <p className="text-sm text-gray-600 mt-1">Manage Clinics, QR Codes & Appointments</p>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Navigation Tabs */}
        <div className="flex space-x-2 mb-8 bg-white rounded-xl shadow-md p-2">
          {[
            { id: 'generate', label: '🏥 Clinics & QR', icon: '🏥' },
            { id: 'patients', label: '👤 Patients', icon: '👤' },
            { id: 'mrs', label: '💼 MR Appointments', icon: '💼' },
            { id: 'clinics', label: '📋 My Clinics', icon: '📋' },
            { id: 'ads', label: '📢 Ads for Dashboard', icon: '📢' },
            { id: 'doctors', label: '👨‍⚕️ Doctors', icon: '👨‍⚕️' }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 px-4 py-3 rounded-lg font-medium transition-all duration-200 ${
                activeTab === tab.id
                  ? 'bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg transform scale-105'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              {tab.label}
              {tab.id === 'patients' && registrations.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-red-500 text-white text-xs rounded-full">
                  {registrations.length}
                </span>
              )}
              {tab.id === 'mrs' && mrRegistrations.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-green-500 text-white text-xs rounded-full">
                  {mrRegistrations.length}
                </span>
              )}
            </button>
          ))}
        </div>

        {activeTab === 'generate' ? (
          // Clinic & QR Generation Tab
          <div className="bg-white rounded-xl shadow-lg p-8">
            <h2 className="text-2xl font-bold text-gray-800">Generate QR Code for Clinic Registration</h2>
            <p className="text-gray-600">Create a clinic and generate QR codes for patient registration.</p>
            
            {message.text && (
              <div className={`mt-4 px-4 py-3 rounded-lg ${
                message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {message.text}
              </div>
            )}
            
            <div className="mt-6">
              {/* Create Clinic Button */}
              <button 
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
                onClick={() => setShowClinicForm(!showClinicForm)}
              >
                {showClinicForm ? 'Cancel' : '+ Create New Clinic'}
              </button>

              {/* Clinic Creation Form */}
              {showClinicForm && (
                <div className="mt-4">
                  <h3 className="text-lg font-semibold text-gray-800">Create New Clinic</h3>
                  <form onSubmit={handleCreateClinic}>
                    <div className="mb-4">
                      <label htmlFor="clinicName" className="block text-gray-700 font-medium mb-2">Clinic/Hospital Name *</label>
                      <input
                        type="text"
                        id="clinicName"
                        name="name"
                        value={clinicData.name}
                        onChange={handleClinicInputChange}
                        placeholder="e.g., City General Clinic"
                        required
                        className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                      />
                    </div>
                    
                    <div className="mb-4">
                      <label htmlFor="clinicAddress" className="block text-gray-700 font-medium mb-2">Address</label>
                      <input
                        type="text"
                        id="clinicAddress"
                        name="address"
                        value={clinicData.address}
                        onChange={handleClinicInputChange}
                        placeholder="e.g., 123 Main Street"
                        className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                      />
                    </div>
                    
                    <div className="mb-4">
                      <label htmlFor="clinicPhone" className="block text-gray-700 font-medium mb-2">Phone Number</label>
                      <input
                        type="tel"
                        id="clinicPhone"
                        name="phone"
                        value={clinicData.phone}
                        onChange={handleClinicInputChange}
                        placeholder="e.g., +1234567890"
                        className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                      />
                    </div>
                    
                    <div className="mb-4">
                      <label htmlFor="clinicDepartment" className="block text-gray-700 font-medium mb-2">Department</label>
                      <input
                        type="text"
                        id="clinicDepartment"
                        name="department"
                        value={clinicData.department}
                        onChange={handleClinicInputChange}
                        placeholder="e.g., General, Cardiology, etc."
                        className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                      />
                    </div>
                    
                    <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md" disabled={loading}>
                      {loading ? 'Creating...' : 'Create Clinic'}
                    </button>
                  </form>
                </div>
              )}

              {/* Clinic Selection and QR Generation */}
              <div className="mt-4">
                <label htmlFor="clinicSelect" className="block text-gray-700 font-medium mb-2">Select Clinic:</label>
                <div className="flex gap-2 mb-4">
                  <select
                    id="clinicSelect"
                    value={selectedClinic}
                    onChange={(e) => setSelectedClinic(e.target.value)}
                    className="flex-1 px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                  >
                    <option value="">Select a clinic</option>
                    {clinics.map(clinic => (
                      <option key={clinic.id} value={clinic.id}>
                        {clinic.name}
                      </option>
                    ))}
                  </select>
                  {selectedClinic && (
                    <button
                      onClick={() => {
                        const clinic = clinics.find(c => c.id === selectedClinic);
                        if (clinic) handleEditClinic(clinic);
                      }}
                      className="px-4 py-3 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition-colors shadow-md"
                      title="Edit Selected Clinic"
                    >
                      ✏️ Edit
                    </button>
                  )}
                </div>
                
                <div className="flex gap-4">
                  <button 
                    className="flex-1 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md font-semibold" 
                    onClick={generateQRCode} 
                    disabled={!selectedClinic}
                  >
                    🏥 Generate Patient QR
                  </button>
                  <button 
                    className="flex-1 px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors shadow-md font-semibold" 
                    onClick={generateMRQRCode} 
                    disabled={!selectedClinic}
                  >
                    💼 Generate MR QR
                  </button>
                </div>
              </div>

              {qrValue && (
                <div className="mt-6 p-6 bg-gradient-to-r from-purple-50 to-blue-50 rounded-xl border-2 border-purple-200">
                  <div className="text-center">
                    <QRCode value={qrValue} size={256} level="H" includeMargin={true} />
                    <p className="mt-4 text-lg font-semibold text-gray-800">
                      {qrValue.includes('mr-register') ? '💼 MR Appointment QR Code' : '🏥 Patient Registration QR Code'}
                    </p>
                    <p className="mt-2 text-gray-600">
                      Scan to register at {clinics.find(c => c.id === selectedClinic)?.name}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">
                      Hospital name will be auto-filled when scanned
                    </p>
                  </div>
                </div>
              )}
              
              {/* All Generated QR Codes */}
              {generatedQRs.length > 0 && (
                <div className="mt-6">
                  <h3 className="text-lg font-semibold text-gray-800 mb-4">All Generated QR Codes ({generatedQRs.length})</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {generatedQRs.map((qr, index) => (
                      <div key={qr.id} className="bg-white rounded-xl shadow-lg p-6 border-2 hover:border-blue-400 transition-all">
                        <div className="flex items-start justify-between mb-4">
                          <div>
                            <span className={`inline-block px-3 py-1 text-xs font-semibold rounded-full mb-2 ${
                              qr.type === 'mr' 
                                ? 'bg-purple-100 text-purple-800' 
                                : 'bg-blue-100 text-blue-800'
                            }`}>
                              {qr.type === 'mr' ? '💼 MR' : '🏥 Patient'}
                            </span>
                            <h4 className="text-gray-800 font-semibold">{qr.clinicName}</h4>
                          </div>
                          <div className="flex gap-2">
                            <button
                              onClick={() => handleViewQR(qr)}
                              className="p-2 bg-blue-100 text-blue-600 rounded-lg hover:bg-blue-200 transition-colors"
                              title="View QR Code"
                            >
                              👁️
                            </button>
                            <button
                              onClick={() => handleDownloadQR(qr)}
                              className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200 transition-colors"
                              title="Download QR Code"
                            >
                              ⬇️
                            </button>
                            <button
                              onClick={() => handleDeleteQR(qr.id)}
                              className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors"
                              title="Delete QR Code"
                            >
                              🗑️
                            </button>
                          </div>
                        </div>
                        
                        <div className="aspect-square bg-gray-50 rounded-lg flex items-center justify-center mb-3">
                          <QRCode value={qr.qrUrl} size={120} level="H" includeMargin={true} />
                        </div>
                        
                        <p className="text-xs text-gray-500 text-center">
                          {new Date(qr.createdAt).toLocaleDateString()} at {new Date(qr.createdAt).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {/* Registered Users List */}
              <div className="mt-6">
                <h3 className="text-lg font-semibold text-gray-800">Recent Registrations ({registrations.length})</h3>
                {registrations.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {registrations.slice(0, 10).map(reg => (
                      <div key={reg.id} className="bg-white rounded-lg shadow-lg p-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <strong className="text-gray-800">{reg.fullName}</strong>
                            <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                              {reg.hospitalName}
                            </span>
                          </div>
                          <span className="px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                            {reg.status}
                          </span>
                        </div>
                        <div className="mt-2">
                          <span className="block text-gray-600">{reg.email}</span>
                          <span className="block text-gray-600">{reg.mobileNumber}</span>
                        </div>
                        <div className="mt-2 text-gray-400">
                          {new Date(reg.createdAt.seconds * 1000).toLocaleString()}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-center py-12 text-gray-500">
                    <p className="text-lg">No registrations yet.</p>
                  </p>
                )}
              </div>
            </div>
          </div>
        ) : activeTab === 'patients' ? (
          // Patient Registrations Tab
          <div className="bg-white rounded-xl shadow-lg p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-800">👤 Patient Registrations</h2>
              <button
                onClick={exportToCSV}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
              >
                📊 Export CSV
              </button>
            </div>
            
            {/* Search and Filter */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <input
                type="text"
                placeholder="🔍 Search by name, email, or phone..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
              />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
              >
                <option value="all">All Status</option>
                <option value="registered">Registered</option>
                <option value="attended">Attended</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>

            {/* Registrations Table */}
            <div className="overflow-x-auto">
              <table className="w-full bg-white rounded-lg overflow-hidden">
                <thead className="bg-gradient-to-r from-blue-600 to-blue-700 text-white">
                  <tr>
                    <th className="px-6 py-4 text-left font-semibold">Patient</th>
                    <th className="px-6 py-4 text-left font-semibold">Contact</th>
                    <th className="px-6 py-4 text-left font-semibold">Hospital</th>
                    <th className="px-6 py-4 text-left font-semibold">Visit Type</th>
                    <th className="px-6 py-4 text-left font-semibold">Symptoms</th>
                    <th className="px-6 py-4 text-left font-semibold">Status</th>
                    <th className="px-6 py-4 text-left font-semibold">Date</th>
                    <th className="px-6 py-4 text-left font-semibold">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRegistrations.map(reg => (
                    <tr key={reg.id} className="border-b hover:bg-blue-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-gray-800">{reg.fullName}</div>
                        <div className="text-sm text-gray-500">{reg.email}</div>
                        <div className="text-sm text-gray-500">{reg.mobileNumber}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-700">{reg.email}</div>
                        <div className="text-sm text-gray-600">{reg.mobileNumber}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
                          {reg.hospitalName}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm text-gray-700">{reg.visitType}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm text-gray-700">{reg.symptoms}</span>
                      </td>
                      <td className="px-6 py-4">
                        <select
                          value={reg.status}
                          onChange={(e) => updatePatientStatus(reg.id, e.target.value)}
                          className={`px-3 py-1 rounded-full text-sm font-semibold ${
                            reg.status === 'attended' ? 'bg-green-100 text-green-800' :
                            reg.status === 'registered' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-red-100 text-red-800'
                          }`}
                        >
                          <option value="registered">Registered</option>
                          <option value="attended">Attended</option>
                          <option value="cancelled">Cancelled</option>
                        </select>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex space-x-2">
                          <button
                            onClick={() => alert(`Contact: ${reg.mobileNumber}`)}
                            className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200 transition-colors"
                            title="Contact"
                          >
                            📞
                          </button>
                          <button
                            onClick={() => deleteRegistration(reg.id)}
                            className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors"
                            title="Delete"
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {filteredRegistrations.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  <p className="text-lg">No registrations found</p>
                </div>
              )}
            </div>
          </div>
        ) : activeTab === 'mrs' ? (
          // MR Appointments Tab
          <div className="bg-white rounded-xl shadow-lg p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-800">💼 Medical Representative Appointments</h2>
              <button
                onClick={() => {
                  const csvData = mrRegistrations.map(mr => [
                    mr.fullName, mr.company, mr.email, mr.mobileNumber,
                    mr.specialty, mr.visitPurpose, mr.preferredDate, mr.preferredTime,
                    mr.hospitalName, mr.status
                  ]);
                  // Export logic similar to patients
                }}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors shadow-md"
              >
                📊 Export CSV
              </button>
            </div>
            
            {/* Search and Filter */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <input
                type="text"
                placeholder="🔍 Search by name, company, email, or phone..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
              />
              <select
                value={mrStatusFilter}
                onChange={(e) => setMrStatusFilter(e.target.value)}
                className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
              >
                <option value="all">All Status</option>
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="rejected">Rejected</option>
                <option value="completed">Completed</option>
              </select>
            </div>

            {/* MR Table */}
            <div className="overflow-x-auto">
              <table className="w-full bg-white rounded-lg overflow-hidden">
                <thead className="bg-gradient-to-r from-blue-600 to-blue-700 text-white">
                  <tr>
                    <th className="px-6 py-4 text-left font-semibold">MR Details</th>
                    <th className="px-6 py-4 text-left font-semibold">Company & Specialty</th>
                    <th className="px-6 py-4 text-left font-semibold">Hospital</th>
                    <th className="px-6 py-4 text-left font-semibold">Preferred Date/Time</th>
                    <th className="px-6 py-4 text-left font-semibold">Purpose</th>
                    <th className="px-6 py-4 text-left font-semibold">Status</th>
                    <th className="px-6 py-4 text-left font-semibold">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMRs.map(mr => (
                    <tr key={mr.id} className="border-b hover:bg-blue-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-gray-800">{mr.fullName}</div>
                        <div className="text-sm text-gray-500">{mr.email}</div>
                        <div className="text-sm text-gray-500">{mr.mobileNumber}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-medium text-gray-700">{mr.company}</div>
                        <div className="text-sm text-gray-600">{mr.specialty}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
                          {mr.hospitalName}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-700">📅 {mr.preferredDate}</div>
                        <div className="text-sm text-gray-600">🕐 {mr.preferredTime}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm text-gray-700">{mr.visitPurpose}</span>
                      </td>
                      <td className="px-6 py-4">
                        <select
                          value={mr.status}
                          onChange={(e) => updateMRStatus(mr.id, e.target.value)}
                          className={`px-3 py-1 rounded-full text-sm font-semibold ${
                            mr.status === 'approved' ? 'bg-green-100 text-green-800' :
                            mr.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                            mr.status === 'rejected' ? 'bg-red-100 text-red-800' :
                            'bg-blue-100 text-blue-800'
                          }`}
                        >
                          <option value="pending">Pending</option>
                          <option value="approved">Approved</option>
                          <option value="rejected">Rejected</option>
                          <option value="completed">Completed</option>
                        </select>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex space-x-2">
                          <button
                            onClick={() => alert(`Contact: ${mr.mobileNumber}`)}
                            className="p-2 bg-green-100 text-green-600 rounded-lg hover:bg-green-200 transition-colors"
                            title="Contact"
                          >
                            📞
                          </button>
                          <button
                            onClick={() => deleteMRRegistration(mr.id)}
                            className="p-2 bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors"
                            title="Delete"
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              
              {filteredMRs.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  <p className="text-lg">No MR appointments found</p>
                </div>
              )}
            </div>
          </div>
        ) : activeTab === 'clinics' ? (
          // Clinics Management Tab
          <div className="bg-white rounded-xl shadow-lg p-8">
            <h2 className="text-2xl font-bold text-gray-800">📋 My Clinics</h2>
            
            <button 
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
              onClick={() => setShowClinicForm(true)}
            >
              + Create New Clinic
            </button>

            {/* Clinic Creation Form */}
            {showClinicForm && (
              <div className="mt-4">
                <h3 className="text-lg font-semibold text-gray-800">Create New Clinic</h3>
                <form onSubmit={handleCreateClinic}>
                  <div className="mb-4">
                    <label htmlFor="clinicName" className="block text-gray-700 font-medium mb-2">Clinic/Hospital Name *</label>
                    <input
                      type="text"
                      id="clinicName"
                      name="name"
                      value={clinicData.name}
                      onChange={handleClinicInputChange}
                      placeholder="e.g., City General Clinic"
                      required
                      className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    />
                  </div>
                  
                  <div className="mb-4">
                    <label htmlFor="clinicAddress" className="block text-gray-700 font-medium mb-2">Address</label>
                    <input
                      type="text"
                      id="clinicAddress"
                      name="address"
                      value={clinicData.address}
                      onChange={handleClinicInputChange}
                      placeholder="e.g., 123 Main Street"
                      className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    />
                  </div>
                  
                  <div className="mb-4">
                    <label htmlFor="clinicPhone" className="block text-gray-700 font-medium mb-2">Phone Number</label>
                    <input
                      type="tel"
                      id="clinicPhone"
                      name="phone"
                      value={clinicData.phone}
                      onChange={handleClinicInputChange}
                      placeholder="e.g., +1234567890"
                      className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    />
                  </div>
                  
                  <div className="mb-4">
                    <label htmlFor="clinicDepartment" className="block text-gray-700 font-medium mb-2">Department</label>
                    <input
                      type="text"
                      id="clinicDepartment"
                      name="department"
                      value={clinicData.department}
                      onChange={handleClinicInputChange}
                      placeholder="e.g., General, Cardiology, etc."
                      className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    />
                  </div>
                  
                  <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md" disabled={loading}>
                    {loading ? 'Creating...' : 'Create Clinic'}
                  </button>
                </form>
              </div>
            )}

            {/* Clinics List */}
            <div className="mt-6">
              {clinics.map(clinic => (
                <div key={clinic.id} className="bg-white rounded-lg shadow-lg p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-800">{clinic.name}</h3>
                      <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                        {clinic.department || 'General'}
                      </span>
                    </div>
                    <button 
                      className="px-2 py-1 bg-blue-100 text-blue-800 rounded-lg hover:bg-blue-200 transition-colors"
                      onClick={() => {
                        setSelectedClinic(clinic.id);
                        setActiveTab('generate');
                        generateQRCode();
                      }}
                    >
                      Generate QR Code
                    </button>
                  </div>
                  <div className="mt-2">
                    {clinic.address && <p className="text-gray-600">📍 {clinic.address}</p>}
                    {clinic.phone && <p className="text-gray-600">📞 {clinic.phone}</p>}
                  </div>
                  <div className="mt-2">
                    <span className="px-2 py-0.5 bg-green-100 text-green-800 text-xs rounded-full">
                      QR Codes: {generatedQRs.filter(qr => qr.clinicId === clinic.id).length}
                    </span>
                    <span className="ml-2 px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full">
                      Patients: {registrations.filter(r => r.hospitalId === clinic.id).length}
                    </span>
                  </div>
                </div>
              ))}  
              
              {clinics.length === 0 && (
                <div className="text-center py-12 text-gray-500">
                  <p className="text-lg">No clinics created yet. Click "+ Create New Clinic" to get started.</p>
                </div>
              )}
            </div>
          </div>
        ) : activeTab === 'ads' ? (
          // Ads Management Tab - For Doctor Dashboard
          <div className="bg-white rounded-xl shadow-lg p-8">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-800">📢 Manage Ads for Doctor Dashboard</h2>
                <p className="text-gray-600 mt-1">Create and manage ads that appear on the doctor dashboard</p>
              </div>
              <button 
                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg font-semibold"
                onClick={() => {
                  setEditingAd(null);
                  setAdFormData({
                    title: '',
                    imageUrl: '',
                    targetUrl: '',
                    priority: 0,
                    clinicId: '',
                    isActive: true
                  });
                  setShowAdForm(true);
                }}
              >
                + Create New Ad
              </button>
            </div>

            {message.text && (
              <div className={`mb-6 px-4 py-3 rounded-lg ${
                message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {message.text}
              </div>
            )}

            {/* Ad Form */}
            {showAdForm && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                  <div className="p-8">
                    <h3 className="text-2xl font-bold text-gray-800 mb-6">
                      {editingAd ? '✏️ Edit Ad' : '➕ Create New Ad'}
                    </h3>
                    
                    <form onSubmit={handleSaveAd}>
                      <div className="space-y-4">
                        <div>
                          <label className="block text-gray-700 font-medium mb-2">Ad Title *</label>
                          <input
                            type="text"
                            name="title"
                            value={adFormData.title}
                            onChange={handleAdInputChange}
                            placeholder="e.g., Special Offer, Health Campaign"
                            required
                            className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                          />
                        </div>

                        <div>
                          <label className="block text-gray-700 font-medium mb-2">Image URL *</label>
                          <input
                            type="url"
                            name="imageUrl"
                            value={adFormData.imageUrl}
                            onChange={handleAdInputChange}
                            placeholder="https://example.com/ad-image.jpg"
                            required
                            className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                          />
                        </div>

                        <div>
                          <label className="block text-gray-700 font-medium mb-2">Target URL (Optional)</label>
                          <input
                            type="url"
                            name="targetUrl"
                            value={adFormData.targetUrl}
                            onChange={handleAdInputChange}
                            placeholder="https://example.com/offer"
                            className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                          />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <label className="block text-gray-700 font-medium mb-2">Priority</label>
                            <input
                              type="number"
                              name="priority"
                              value={adFormData.priority}
                              onChange={handleAdInputChange}
                              placeholder="0"
                              min="0"
                              className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                            />
                          </div>

                          <div>
                            <label className="block text-gray-700 font-medium mb-2">Clinic</label>
                            <select
                              name="clinicId"
                              value={adFormData.clinicId}
                              onChange={handleAdInputChange}
                              className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                            >
                              <option value="">All Clinics (Global)</option>
                              {clinics.map(clinic => (
                                <option key={clinic.id} value={clinic.id}>
                                  {clinic.name}
                                </option>
                              ))}
                            </select>
                          </div>
                        </div>

                        <div className="flex items-center">
                          <input
                            type="checkbox"
                            name="isActive"
                            id="isActive"
                            checked={adFormData.isActive}
                            onChange={handleAdInputChange}
                            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                          />
                          <label htmlFor="isActive" className="ml-2 block text-gray-700 font-medium">
                            Active (Show on dashboard)
                          </label>
                        </div>
                      </div>

                      <div className="flex gap-3 mt-8">
                        <button
                          type="button"
                          onClick={() => {
                            setShowAdForm(false);
                            setEditingAd(null);
                          }}
                          className="flex-1 px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-semibold"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          disabled={loading}
                          className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all font-semibold shadow-lg disabled:opacity-50"
                        >
                          {loading ? 'Saving...' : (editingAd ? 'Update Ad' : 'Create Ad')}
                        </button>
                      </div>
                    </form>
                  </div>
                </div>
              </div>
            )}

            {/* Ads List */}
            <div className="mt-6 space-y-4">
              {ads.length > 0 ? (
                ads.map((ad) => (
                  <div key={ad.id} className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg p-4 border-2 border-blue-200">
                    <div className="flex items-start gap-4">
                      <div className="w-32 h-24 flex-shrink-0 bg-white rounded-lg overflow-hidden border-2 border-gray-200">
                        <img 
                          src={ad.imageUrl} 
                          alt={ad.title}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            e.target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect fill="%23ccc" width="100" height="100"/><text fill="%23666" x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">No Image</text></svg>';
                          }}
                        />
                      </div>

                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <div>
                            <h3 className="text-lg font-bold text-gray-800">{ad.title}</h3>
                            <div className="flex gap-2 mt-1">
                              <span className={`px-2 py-0.5 text-xs rounded-full font-medium ${
                                ad.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
                              }`}>
                                {ad.isActive ? '✓ Active' : '✗ Inactive'}
                              </span>
                              <span className="px-2 py-0.5 bg-blue-100 text-blue-800 text-xs rounded-full font-medium">
                                Priority: {ad.priority}
                              </span>
                              {ad.clinicId ? (
                                <span className="px-2 py-0.5 bg-purple-100 text-purple-800 text-xs rounded-full font-medium">
                                  {clinics.find(c => c.id === ad.clinicId)?.name || 'Specific'}
                                </span>
                              ) : (
                                <span className="px-2 py-0.5 bg-indigo-100 text-indigo-800 text-xs rounded-full font-medium">
                                  All Clinics
                                </span>
                              )}
                            </div>
                            {ad.targetUrl && (
                              <p className="text-sm text-gray-600 mt-2">
                                🔗 <a href={ad.targetUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">Link</a>
                              </p>
                            )}
                          </div>
                          
                          <div className="flex gap-2">
                            <button
                              onClick={() => handleEditAd(ad)}
                              className="px-3 py-1 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition-colors text-sm font-medium"
                            >
                              ✏️
                            </button>
                            <button
                              onClick={() => handleDeleteAd(ad.id)}
                              className="px-3 py-1 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm font-medium"
                            >
                              🗑️
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-12">
                  <div className="text-6xl mb-4">📢</div>
                  <h3 className="text-xl font-semibold text-gray-700 mb-2">No Ads Created Yet</h3>
                  <p className="text-gray-500 mb-6">Create your first ad to display on the doctor dashboard</p>
                  <button
                    onClick={() => {
                      setEditingAd(null);
                      setShowAdForm(true);
                    }}
                    className="px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg font-semibold"
                  >
                    + Create Your First Ad
                  </button>
                </div>
              )}
            </div>

            <div className="mt-8 p-6 bg-blue-50 rounded-xl border-2 border-blue-200">
              <h4 className="font-bold text-gray-800 mb-2">ℹ️ How It Works:</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>• Ads appear as scrolling banner on <strong>Doctor Dashboard</strong></li>
                <li>• Higher priority shows first in scroll</li>
                <li>• Select specific clinic or leave empty for all</li>
                <li>• Toggle "Active" to show/hide instantly</li>
              </ul>
            </div>
          </div>
        ) : activeTab === 'doctors' ? (
          // Doctors Management Tab
          <div className="bg-white rounded-xl shadow-lg p-8">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-800">👨‍⚕️ Manage Registered Doctors</h2>
                <p className="text-gray-600 mt-1">View doctors and manage their clinic assignments</p>
              </div>
              <button 
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
                onClick={fetchDoctors}
              >
                🔄 Refresh List
              </button>
            </div>

            {message.text && (
              <div className={`mb-6 px-4 py-3 rounded-lg ${
                message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {message.text}
              </div>
            )}

            {/* Doctors List */}
            <div className="space-y-4">
              {doctors.length > 0 ? (
                doctors.map((doctor) => {
                  // Get clinics assigned to this doctor from clinic_names array
                  const clinicNames = doctor.clinic_names || [];
                  const clinicCount = clinicNames.length;
                  
                  return (
                    <div key={doctor.id} className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-6 border-2 border-blue-200">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-4 flex-1">
                          {/* Doctor Avatar */}
                          <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white text-2xl font-bold flex-shrink-0">
                            {doctor.name?.charAt(0).toUpperCase() || 'D'}
                          </div>

                          {/* Doctor Info */}
                          <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2">
                              <h3 className="text-xl font-bold text-gray-800">{doctor.name}</h3>
                              <span className="px-3 py-1 bg-blue-100 text-blue-800 text-xs rounded-full font-medium">
                                Dr.
                              </span>
                            </div>
                            
                            <div className="grid grid-cols-2 gap-4 mb-3">
                              <div>
                                <p className="text-sm text-gray-500 mb-1">📧 Email</p>
                                <p className="text-sm font-medium text-gray-800">{doctor.email}</p>
                              </div>
                              <div>
                                <p className="text-sm text-gray-500 mb-1">📱 Phone</p>
                                <p className="text-sm font-medium text-gray-800">{doctor.phone || 'Not provided'}</p>
                              </div>
                            </div>

                            {/* Clinic Assignments */}
                            <div className="mt-4">
                              <p className="text-sm font-semibold text-gray-700 mb-2">
                                🏥 Assigned Clinics ({clinicCount})
                              </p>
                              <div className="flex flex-wrap gap-2">
                                {clinicCount > 0 ? (
                                  clinicNames.map((clinicName, index) => (
                                    <span key={index} className="px-3 py-1 bg-indigo-100 text-indigo-800 text-sm rounded-full font-medium">
                                      {clinicName}
                                    </span>
                                  ))
                                ) : (
                                  <span className="px-3 py-1 bg-gray-100 text-gray-600 text-sm rounded-full italic">
                                    No clinics assigned
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Quick Stats */}
                      <div className="mt-4 pt-4 border-t border-blue-200 grid grid-cols-3 gap-4">
                        <div className="text-center">
                          <p className="text-2xl font-bold text-blue-600">
                            {clinicCount}
                          </p>
                          <p className="text-xs text-gray-600 mt-1">Total Clinics</p>
                        </div>
                        <div className="text-center">
                          <p className="text-2xl font-bold text-green-600">
                            Active
                          </p>
                          <p className="text-xs text-gray-600 mt-1">Status</p>
                        </div>
                        <div className="text-center">
                          <p className="text-2xl font-bold text-purple-600">
                            {new Date(doctor.created_at).toLocaleDateString()}
                          </p>
                          <p className="text-xs text-gray-600 mt-1">Joined</p>
                        </div>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="text-center py-12">
                  <div className="text-6xl mb-4">👨‍⚕️</div>
                  <h3 className="text-xl font-semibold text-gray-700 mb-2">No Doctors Found</h3>
                  <p className="text-gray-500">Doctors registered in the system will appear here</p>
                </div>
              )}
            </div>

            {/* Info Box */}
            <div className="mt-8 p-6 bg-blue-50 rounded-xl border-2 border-blue-200">
              <h4 className="font-bold text-gray-800 mb-2">ℹ️ Doctor Management:</h4>
              <ul className="text-sm text-gray-700 space-y-1">
                <li>• View all registered doctors from the backend database</li>
                <li>• See how many clinics each doctor is assigned to</li>
                <li>• Monitor doctor activity and registration dates</li>
          
              </ul>
            </div>
          </div>
        ) : null}
      </div>
      
      {/* QR Code Modal */}
      {showQRModal && viewingQR && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full p-8 relative animate-fade-in">
            <button
              onClick={() => setShowQRModal(false)}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
            >
              ✕
            </button>
            
            <div className="text-center mb-6">
              <h3 className="text-2xl font-bold text-gray-800 mb-2">
                {viewingQR.type === 'mr' ? '💼 MR Appointment QR' : '🏥 Patient Registration QR'}
              </h3>
              <p className="text-gray-600 font-semibold">{viewingQR.clinicName}</p>
            </div>
            
            <div className="aspect-square bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl flex items-center justify-center p-8 mb-6 border-2 border-blue-200">
              <QRCode value={viewingQR.qrUrl} size={300} level="H" includeMargin={true} />
            </div>
            
            <div className="flex gap-3">
              <button
                onClick={() => downloadQRAsPNG(viewingQR)}
                className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold shadow-md"
              >
                ⬇️ Download PNG
              </button>
              <button
                onClick={() => {
                  navigator.clipboard.writeText(viewingQR.qrUrl);
                  alert('✅ URL copied to clipboard!\n\n' + viewingQR.qrUrl);
                }}
                className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold shadow-md"
              >
                📋 Copy URL
              </button>
            </div>
            
            {/* Clickable Link Button */}
            <div className="mt-4">
              <a
                href={viewingQR.qrUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full px-6 py-3 bg-purple-600 text-white text-center rounded-lg hover:bg-purple-700 transition-colors font-semibold shadow-md"
              >
                🔗 Open Registration Page (New Tab)
              </a>
            </div>
            
            <div className="mt-4 p-4 bg-blue-50 rounded-lg">
              <p className="text-sm text-gray-600">
                <strong>Scan this QR code</strong> to open the registration form for {viewingQR.clinicName}. Hospital name will be auto-filled.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Edit Clinic Modal */}
      {showEditClinicModal && editingClinic && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto animate-fade-in">
            <div className="p-8">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-2xl font-bold text-gray-800">✏️ Edit Clinic Details</h2>
                <button
                  onClick={() => {
                    setShowEditClinicModal(false);
                    setEditingClinic(null);
                  }}
                  className="text-gray-400 hover:text-gray-600 text-2xl"
                >
                  ✕
                </button>
              </div>

              <form onSubmit={handleUpdateClinic} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    🏥 Clinic/Hospital Name
                  </label>
                  <input
                    type="text"
                    value={editingClinic.name}
                    onChange={(e) => setEditingClinic({ ...editingClinic, name: e.target.value })}
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    📍 Address
                  </label>
                  <textarea
                    value={editingClinic.address}
                    onChange={(e) => setEditingClinic({ ...editingClinic, address: e.target.value })}
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    rows="3"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    📞 Phone Number
                  </label>
                  <input
                    type="tel"
                    value={editingClinic.phone}
                    onChange={(e) => setEditingClinic({ ...editingClinic, phone: e.target.value })}
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    🏥 Department
                  </label>
                  <input
                    type="text"
                    value={editingClinic.department}
                    onChange={(e) => setEditingClinic({ ...editingClinic, department: e.target.value })}
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
                    required
                  />
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={() => {
                      setShowEditClinicModal(false);
                      setEditingClinic(null);
                    }}
                    className="flex-1 px-6 py-3 bg-gray-300 text-gray-700 rounded-xl font-semibold hover:bg-gray-400 transition-all"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="flex-1 px-6 py-3 bg-gradient-to-r from-yellow-500 to-orange-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
                    disabled={loading}
                  >
                    {loading ? 'Updating...' : '✅ Update Clinic'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
        </>
      )}
    </div>
  );
}

export default App;