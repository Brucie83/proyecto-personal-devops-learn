import React, { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { Plus, LogOut, CheckCircle, Circle, Edit, Trash2, Filter } from 'lucide-react'
import axios from 'axios'

interface Task {
  id: number
  title: string
  description: string
  completed: boolean
  priority: 'high' | 'medium' | 'low'
  created_at: string
  updated_at: string
}

const Dashboard: React.FC = () => {
  const { user, logout } = useAuth()
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [filter, setFilter] = useState<'all' | 'pending' | 'completed'>('all')
  const [priorityFilter, setPriorityFilter] = useState<'all' | 'high' | 'medium' | 'low'>('all')

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'medium' as 'high' | 'medium' | 'low'
  })

  useEffect(() => {
    fetchTasks()
  }, [])

  const fetchTasks = async () => {
    try {
      const response = await axios.get('/api/tasks')
      setTasks(response.data)
    } catch (error) {
      console.error('Error fetching tasks:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (editingTask) {
        const response = await axios.put(`/api/tasks/${editingTask.id}`, formData)
        setTasks(tasks.map(task => task.id === editingTask.id ? response.data : task))
      } else {
        const response = await axios.post('/api/tasks', formData)
        setTasks([...tasks, response.data])
      }
      resetForm()
    } catch (error) {
      console.error('Error saving task:', error)
    }
  }

  const toggleTask = async (task: Task) => {
    try {
      const response = await axios.put(`/api/tasks/${task.id}`, {
        ...task,
        completed: !task.completed
      })
      setTasks(tasks.map(t => t.id === task.id ? response.data : t))
    } catch (error) {
      console.error('Error toggling task:', error)
    }
  }

  const deleteTask = async (taskId: number) => {
    if (!confirm('¿Estás seguro de eliminar esta tarea?')) return
    
    try {
      await axios.delete(`/api/tasks/${taskId}`)
      setTasks(tasks.filter(task => task.id !== taskId))
    } catch (error) {
      console.error('Error deleting task:', error)
    }
  }

  const editTask = (task: Task) => {
    setEditingTask(task)
    setFormData({
      title: task.title,
      description: task.description,
      priority: task.priority
    })
    setShowModal(true)
  }

  const resetForm = () => {
    setFormData({ title: '', description: '', priority: 'medium' })
    setEditingTask(null)
    setShowModal(false)
  }

  const filteredTasks = tasks.filter(task => {
    if (filter === 'pending' && task.completed) return false
    if (filter === 'completed' && !task.completed) return false
    if (priorityFilter !== 'all' && task.priority !== priorityFilter) return false
    return true
  })

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'text-red-600 bg-red-50 border-red-200'
      case 'medium': return 'text-yellow-600 bg-yellow-50 border-yellow-200'
      case 'low': return 'text-green-600 bg-green-50 border-green-200'
      default: return 'text-gray-600 bg-gray-50 border-gray-200'
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Task Manager</h1>
              <p className="text-gray-600">Bienvenido, {user?.username}</p>
            </div>
            <button
              onClick={logout}
              className="flex items-center space-x-2 text-gray-600 hover:text-gray-800"
            >
              <LogOut size={20} />
              <span>Cerrar Sesión</span>
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Controls */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 space-y-4 sm:space-y-0">
          <div className="flex items-center space-x-4">
            <Filter size={20} className="text-gray-500" />
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="input-field w-auto"
            >
              <option value="all">Todas</option>
              <option value="pending">Pendientes</option>
              <option value="completed">Completadas</option>
            </select>
            <select
              value={priorityFilter}
              onChange={(e) => setPriorityFilter(e.target.value as any)}
              className="input-field w-auto"
            >
              <option value="all">Todas las prioridades</option>
              <option value="high">Alta</option>
              <option value="medium">Media</option>
              <option value="low">Baja</option>
            </select>
          </div>
          <button
            onClick={() => setShowModal(true)}
            className="btn-primary flex items-center space-x-2"
          >
            <Plus size={20} />
            <span>Nueva Tarea</span>
          </button>
        </div>

        {/* Tasks Grid */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredTasks.map(task => (
            <div
              key={task.id}
              className={`task-card priority-${task.priority} ${task.completed ? 'task-completed' : ''}`}
            >
              <div className="flex items-start justify-between mb-3">
                <button
                  onClick={() => toggleTask(task)}
                  className="flex-shrink-0 mr-3 mt-1"
                >
                  {task.completed ? (
                    <CheckCircle className="text-green-500" size={20} />
                  ) : (
                    <Circle className="text-gray-400" size={20} />
                  )}
                </button>
                <div className="flex-1">
                  <h3 className={`font-semibold text-gray-900 ${task.completed ? 'line-through' : ''}`}>
                    {task.title}
                  </h3>
                  {task.description && (
                    <p className={`text-gray-600 text-sm mt-1 ${task.completed ? 'line-through' : ''}`}>
                      {task.description}
                    </p>
                  )}
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getPriorityColor(task.priority)}`}>
                  {task.priority === 'high' ? 'Alta' : task.priority === 'medium' ? 'Media' : 'Baja'}
                </span>
                <div className="flex space-x-2">
                  <button
                    onClick={() => editTask(task)}
                    className="text-gray-400 hover:text-primary-600"
                  >
                    <Edit size={16} />
                  </button>
                  <button
                    onClick={() => deleteTask(task.id)}
                    className="text-gray-400 hover:text-red-600"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredTasks.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">No hay tareas que mostrar</p>
            <button
              onClick={() => setShowModal(true)}
              className="btn-primary mt-4"
            >
              Crear tu primera tarea
            </button>
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4">
              {editingTask ? 'Editar Tarea' : 'Nueva Tarea'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Título
                </label>
                <input
                  type="text"
                  required
                  className="input-field"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Descripción
                </label>
                <textarea
                  className="input-field"
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Prioridad
                </label>
                <select
                  className="input-field"
                  value={formData.priority}
                  onChange={(e) => setFormData({ ...formData, priority: e.target.value as any })}
                >
                  <option value="low">Baja</option>
                  <option value="medium">Media</option>
                  <option value="high">Alta</option>
                </select>
              </div>
              <div className="flex space-x-3 pt-4">
                <button type="submit" className="btn-primary flex-1">
                  {editingTask ? 'Actualizar' : 'Crear'}
                </button>
                <button
                  type="button"
                  onClick={resetForm}
                  className="btn-secondary flex-1"
                >
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}

export default Dashboard
